# 🔗 COMPLETE API MANAGEMENT & SYSTEM INTEGRATION BDD SPECIFICATIONS
# Based on ARGUS WFM CC System - REST API Integration Documentation

Feature: System Integration and API Management - Complete REST API Coverage
  As a system administrator and integration developer
  I want to configure and manage comprehensive external system integrations
  So that data flows seamlessly between ARGUS WFM and other business systems

  Background:
    Given the ARGUS WFM system supports REST API integrations
    And integration services are configured and running
    And external systems are available for data exchange
    And all API endpoints use "application/json" content type
    And proper authentication mechanisms are in place

  # ============================================================================
  # PERSONNEL STRUCTURE INTEGRATION - GET /personnel
  # ============================================================================

  @api_integration @personnel_retrieval @core_endpoint
  Scenario: Personnel Structure Integration via REST API - Complete Specification
    Given I configure integration with external HR system
    When the system calls GET /personnel endpoint with no parameters
    Then it should receive personnel data with exact structure:
      | Field | Type | Required | Description | Validation |
      | services | Array | Yes | List of services in the system | Non-empty array |
      | agents | Array | No | List of employees in the system | Can be empty |
    And services data should include exact service object structure:
      | Service Field | Type | Required | Example | Business Rule |
      | id | String | Yes | "External system" | Unique service identifier |
      | name | String | Yes | "External system" | Service display name |
      | status | String | Yes | "ACTIVE" or "INACTIVE" | Enum values only |
      | serviceGroups | Array | No | Groups within service | Optional grouping |
    And serviceGroups should contain exact group structure:
      | Group Field | Type | Required | Example | Constraint |
      | id | String | Yes | "1" | Unique within service |
      | name | String | Yes | "Individual Support" | Display name |
      | status | String | Yes | "ACTIVE" or "INACTIVE" | Status enum |
      | channelType | String | No | "CHATS,MAILS,INCOMING_CALLS,OUTGOING_CALLS" | Channel classification |

  @api_integration @personnel_agents @detailed_structure
  Scenario: Agent Object Structure - Complete Field Specification
    Given personnel API returns agent data
    When agent objects are processed
    Then each agent should include exact agent object structure:
      | Agent Field | Type | Required | Example | Business Purpose |
      | id | String | Yes | "1" | Unique employee identifier |
      | name | String | Yes | "John" | Employee first name or full name |
      | surname | String | No | "Smith" | Employee last name |
      | secondName | String | No | "William" | Employee middle name |
      | agentNumber | String | No | "230-15" | Personnel/employee number |
      | agentGroups | Array | Yes | Group assignments | Required for planning |
      | loginSSO | String | No | "j.smith" | SSO system login |
    And agentGroups should contain group assignments:
      | Assignment Field | Type | Required | Purpose |
      | groupId | String | Yes | Functional group membership |
    And business rules should be enforced:
      | Business Rule | Validation | Action |
      | Agents without groups | Empty agentGroups | Exclude from response |
      | Name field usage | Single field for full name | Accept if no surname separation |
      | Unique identifiers | No duplicate IDs | Reject duplicates |

  @api_integration @personnel_static_service
  Scenario: Handle Static Service Configuration for Non-Service Systems
    Given external system lacks "service" concept
    When personnel data is requested
    Then system should transmit static service value:
      | Static Field | Required Value | Purpose |
      | id | External system name | Consistent identification |
      | name | External system name | Display consistency |
      | status | "ACTIVE" | Service availability |
    And all external system groups should belong to this static service
    And group structure should remain identical to multi-service systems

  # ============================================================================
  # HISTORICAL DATA INTEGRATION - SERVICE GROUP DATA
  # ============================================================================

  @api_integration @historical_data @service_groups
  Scenario: Historical Data Retrieval by Groups - Complete Parameter Specification
    Given external contact center system has historical call data
    When I request historical data via GET /historic/serviceGroupData
    With exact required parameters:
      | Parameter | Format | Required | Example | Validation Rule |
      | startDate | DateTime (ISO 8601) | Yes | "2020-01-01T00:00:00Z" | Valid datetime with timezone |
      | endDate | DateTime (ISO 8601) | Yes | "2020-01-02T00:00:00Z" | After startDate |
      | step | Integer (milliseconds) | Yes | 300000 | Positive integer (300000 = 5 minutes) |
      | groupId | String (comma-separated) | Yes | "1,2" | Valid group identifiers |
    Then the system should return ServiceGroupHistoricData array
    And each object should contain exact structure:
      | Field | Type | Required | Purpose |
      | serviceId | String | Yes | Service identifier (static "1" if no services) |
      | groupId | String | Yes | Group identifier from request |
      | historicData | Array | Yes | Interval-based historical metrics |

  @api_integration @historical_data @interval_structure
  Scenario: Historical Data Interval Structure - Precise Metric Definitions
    Given historical data is requested for specific intervals
    When HistoricData objects are returned
    Then each interval should contain exact metric structure:
      | Metric Field | Type | Required | Calculation | Example |
      | startInterval | DateTime | Yes | N-minute interval start | "2020-01-01T00:00:00Z" |
      | endInterval | DateTime | Yes | N-minute interval end | "2020-01-01T00:05:00Z" |
      | notUniqueReceived | Integer | Yes | All contacts received in interval | 15 |
      | notUniqueTreated | Integer | Yes | All contacts processed in interval | 10 |
      | notUniqueMissed | Integer | Yes | All contacts lost/missed in interval | 5 |
      | receivedCalls | Integer | Yes | Unique contacts received | 10 |
      | treatedCalls | Integer | Yes | Unique contacts processed | 8 |
      | missCalls | Integer | Yes | Unique contacts lost/missed | 2 |
      | aht | Integer | Yes | Average handling time (milliseconds) | 360000 |
      | postProcessing | Integer | Yes | Post-processing time (milliseconds) | 3000 |

  @api_integration @historical_data @business_rules
  Scenario: Historical Data Business Rules and Calculations
    Given contact data needs proper classification
    When calculating historical metrics
    Then uniqueness should be determined by:
      | Uniqueness Rule | Definition | Application |
      | Customer identifier | Same customer within day | First contact = unique |
      | Device identifier | Same device within day | Alternative to customer ID |
      | Non-unique counting | All contacts within day | Include repeats |
    And time calculations should follow exact formulas:
      | Calculation | Formula | Components |
      | AHT | Total handle time / non-unique processed | Ring + talk + hold time |
      | Post-processing | Total post-process time / non-unique processed | Wrap-up + relax time |
      | Contact classification | Start time determines interval | Based on contact initiation |
    And data exclusions should be applied:
      | Exclusion Rule | Criteria | Rationale |
      | Bot-closed chats | No agent participation | Not workforce-relevant |
      | System-generated | Automated contacts | Focus on human-handled |
      | Test contacts | Marked as test data | Exclude from metrics |

  # ============================================================================
  # AGENT STATUS AND LOGIN DATA INTEGRATION
  # ============================================================================

  @api_integration @agent_status @historical_tracking
  Scenario: Agent Status Data Integration - Complete Status Tracking
    Given I need historical agent status information
    When I call GET /historic/agentStatusData with exact parameters:
      | Parameter | Format | Required | Example | Purpose |
      | startDate | DateTime | Yes | "2020-01-01T00:00:00Z" | Period start |
      | endDate | DateTime | Yes | "2020-01-02T00:00:00Z" | Period end |
      | agentId | String (comma-separated) | Yes | "1,2" | Agent list |
    Then the response should include AgentState objects:
      | AgentState Field | Type | Required | Description |
      | serviceId | String | No | Service identifier (can be empty) |
      | groupId | String | No | Group identifier (can be empty) |
      | agentId | String | Yes | Agent unique identifier |
      | states | Array | Yes | List of status periods |
    And each status period should contain exact state structure:
      | State Field | Type | Required | Content | Business Rule |
      | startDate | DateTime | Yes | "2020-01-01T10:15:36Z" | Status entry time |
      | endDate | DateTime | Yes | "2020-01-01T10:18:36Z" | Status exit time |
      | stateCode | String | Yes | "Break" | Unique status identifier |
      | stateName | String | Yes | "Technical break" | Human-readable status |

  @api_integration @agent_status @status_scope_rules
  Scenario: Agent Status Scope and Linking Rules
    Given agent status data can be linked to groups
    When status information is transmitted
    Then status scope should follow these rules:
      | Scope Type | Implementation | Use Case |
      | Service-group scope | Status linked to specific group | Group-specific work |
      | All-group scope | Status applies to all agent groups | Global status change |
      | No-group scope | Status without group link | System-wide status |
    And status code formation should handle:
      | Status Scenario | Code Formation | Name Formation |
      | Simple status | Use status ID | Use status name |
      | Status with reason | Status ID + reason ID | Status name + reason name |
      | Multi-level status | Hierarchical coding | Descriptive naming |

  @api_integration @agent_login @session_tracking
  Scenario: Agent Login/Logout Data - Session Management
    Given I need agent presence tracking
    When I call GET /historic/agentLoginData with parameters:
      | Parameter | Value | Validation |
      | startDate | "2020-01-01T00:00:00Z" | Within valid range |
      | endDate | "2020-01-02T00:00:00Z" | After start date |
      | agentId | "1,2,3" | Valid agent IDs |
    Then the response should return AgentLogins objects:
      | AgentLogins Field | Type | Content |
      | agentId | String | "1" |
      | logins | Array | Session periods |
    And each login session should contain exact session data:
      | Session Field | Type | Required | Example | Calculation |
      | loginDate | DateTime | Yes | "2020-01-01T10:03:15Z" | Session start |
      | logoutDate | DateTime | Yes | "2020-01-01T12:30:05Z" | Session end |
      | duration | Integer | Yes | 8810000 | Milliseconds logged in |
    And session business rules should apply:
      | Business Rule | Implementation | Purpose |
      | Overlapping sessions | Use latest login | Handle concurrent logins |
      | Incomplete sessions | Handle missing logout | End-of-day processing |
      | Duration calculation | Exact millisecond precision | Accurate time tracking |

  @api_integration @agent_calls @contact_tracking
  Scenario: Agent Contact Processing Data - Individual Performance
    Given I need individual agent performance data
    When I call GET /historic/agentCallsData with parameters:
      | Parameter | Example | Purpose |
      | startDate | "2020-01-01T00:00:00Z" | Analysis period start |
      | endDate | "2020-01-02T00:00:00Z" | Analysis period end |
      | agentId | "1,2" | Specific agents |
    Then the response should return AgentCalls objects:
      | AgentCalls Field | Type | Required | Purpose |
      | agentId | String | Yes | Agent identifier |
      | serviceId | String | Yes | Service context (static "1") |
      | groupId | String | Yes | Group context |
      | agentCalls | Array | Yes | Contact list |
    And each contact should include exact call data:
      | Call Field | Type | Required | Content | Purpose |
      | startCall | DateTime | Yes | "2020-01-01T10:03:15Z" | Contact start time |
      | endCall | DateTime | Yes | "2020-01-01T10:08:15Z" | Contact end time |
      | duration | Integer | Yes | 300000 | Contact duration (milliseconds) |
    And contact selection should include contacts with start time in requested period

  # ============================================================================
  # CHAT PLATFORM SPECIFIC INTEGRATION
  # ============================================================================

  @api_integration @chat_platform @work_time_tracking
  Scenario: Chat Work Time Integration - Platform-Specific Features
    Given integration is performed with chat platform
    When I call GET /historic/agentChatsWorkTime for chat-specific data
    With parameters:
      | Parameter | Example | Chat-Specific Rule |
      | startDate | "2020-01-01T00:00:00Z" | Full day periods preferred |
      | endDate | "2020-01-03T00:00:00Z" | Multi-day analysis |
      | agentId | "1,2,3" | Chat-capable agents |
    Then the response should return AgentChatsWorkTime objects:
      | Field | Type | Content | Chat Business Rule |
      | agentId | String | "1" | Agent identifier |
      | workDate | Date | "2020-01-01" | Calendar date |
      | workTime | Integer | 3600000 | Milliseconds with at least 1 chat |
    And chat work time calculation should follow exact rules:
      | Calculation Rule | Implementation | Example |
      | At least one chat | Count seconds with ≥1 active chat | Multiple chats = count once |
      | Period boundaries | Don't count time outside request period | Respect start/end dates |
      | Overlapping chats | Single time counting for parallel chats | No double counting |
      | Cross-day chats | Split calculation by calendar days | Day boundary handling |

  @api_integration @chat_platform @time_calculation_example
  Scenario: Chat Work Time Calculation - Precise Example Implementation
    Given request period "2020-01-01 00:00:00" to "2020-01-02 00:00:00"
    And agent processed chats in these intervals:
      | Chat Session | Start | End | Day Coverage |
      | Session 1 | 2020-01-01 22:45:00 | 2020-01-01 23:02:00 | Fully in day 1 |
      | Session 2 | 2020-01-01 22:58:00 | 2020-01-02 00:12:00 | Spans days |
    When calculating work time for 2020-01-01
    Then the system should calculate:
      | Time Period | Duration | Reason |
      | 22:45:00-23:02:00 | 17 minutes | Session 1 complete |
      | 23:02:00-00:00:00 | 58 minutes | Session 2 partial (before midnight) |
      | Total | 75 minutes | Combined unique time |
    And return 4500000 milliseconds (75 minutes) for 2020-01-01
    And overlapping period 22:58:00-23:02:00 should be counted only once

  # ============================================================================
  # ADVANCED CALCULATION ALGORITHMS
  # ============================================================================

  @api_integration @calculations @contact_uniqueness @critical
  Scenario: Contact Uniqueness Determination Algorithms
    Given historical data contains contact processing metrics
    When calculating contact uniqueness and handling times
    Then contact uniqueness should be determined by:
      | Uniqueness Type | Method | Scope | Algorithm |
      | Daily unique contacts | Customer identifier | Single day | First contact per customer per day |
      | Unique by device | Device identifier | Daily scope | First contact per device per day |
      | Transfer handling | Separate call counting | Per transfer | Each transfer leg counted separately |
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

  @api_integration @calculations @empty_intervals @edge_case
  Scenario: Empty Interval Handling for Data Efficiency
    Given historical data request for time period with no contacts
    When N-minute intervals contain no contact activity
    Then empty interval handling should follow configuration:
      | Configuration Option | Implementation | Data Efficiency |
      | Include empty intervals | Return intervals with zero values | Complete time series |
      | Skip empty intervals | Exclude from response | Reduced payload |
      | Optional transmission | Configurable per request | Flexible optimization |
    And empty interval structure should be:
      | Field | Value | Purpose |
      | startInterval | DateTime | Interval start time |
      | endInterval | DateTime | Interval end time |
      | All metrics | 0 | Zero values for no activity |
    And data efficiency should consider:
      | Scenario | Recommendation | Rationale |
      | Long periods with no activity | Skip empty intervals | Reduce bandwidth |
      | Real-time monitoring | Include empty intervals | Complete timeline |
      | Reporting analytics | Include empty intervals | Data completeness |

  @api_integration @chat_platform @bot_exclusion @data_quality
  Scenario: Bot-Closed Chat Exclusion from WFMCC Transmission
    Given chat platform processes both agent and bot interactions
    When determining contacts for WFMCC transmission
    Then bot-closed chat exclusion should apply:
      | Chat Type | Agent Participation | WFMCC Transmission | Reason |
      | Agent-handled chat | Yes | Include | Workforce relevant |
      | Bot-closed chat | No | Exclude | No agent participation |
      | Mixed chat (bot + agent) | Yes | Include | Agent involvement |
      | Transferred to agent | Yes | Include | Agent processed |
    And bot detection should identify:
      | Bot Indicator | Detection Method | Exclusion Rule |
      | No agent assignment | System metadata | Exclude completely |
      | Bot-only resolution | Chat flow analysis | Exclude from metrics |
      | Automated responses only | Message content analysis | Exclude from agent stats |
    And exclusion impact should be:
      | Metric Category | Impact | Handling |
      | Contact volume | Reduced by bot contacts | More accurate agent load |
      | Agent performance | Higher accuracy | Bot interference removed |
      | Service levels | Agent-focused metrics | True service capability |

  @api_integration @real_time @error_exclusion @special_handling
  Scenario: Error Response Exclusion for Status Transmission
    Given status transmission operates in real-time mode
    When status transmission encounters API errors
    Then error handling should follow special rules:
      | Error Scenario | Standard API Response | Status Transmission Response |
      | Network timeout | HTTP 500 with details | Continue transmission, log error |
      | Authentication failure | HTTP 401 with message | Queue for retry, alert admin |
      | Service unavailable | HTTP 503 with retry | Circuit breaker, buffer locally |
      | Invalid data format | HTTP 400 with validation | Log and skip, continue stream |
    And status transmission continuity should ensure:
      | Continuity Rule | Implementation | Business Impact |
      | Never block real-time flow | Asynchronous error handling | Uninterrupted monitoring |
      | Buffer failed transmissions | Local queue with retry | No data loss |
      | Alert on persistent failures | Administrative notifications | Operations awareness |
    And error exclusion should not affect:
      | Operation | Continues Normally | Error Handling |
      | Other API endpoints | Standard error responses | Normal HTTP codes |
      | Data retrieval APIs | Full error details | Complete error info |
      | Configuration APIs | Standard validation | Detailed error messages |

  @api_integration @calculations @aht_algorithms @critical
  Scenario: Average Handling Time (AHT) Calculation Components
    Given contact handling data requires precise AHT calculation
    When calculating AHT for contacts
    Then AHT components should be calculated:
      | AHT Component | Calculation | Purpose |
      | Ring time | Time from queue entry to answer | Wait component |
      | Talk time | Active conversation duration | Productive time |
      | Hold time | Customer on hold duration | Service component |
      | Post-processing time | Wrap-up/relax duration | Administrative time |
      | Total AHT | Sum of all components | Complete handling time |
    And AHT business rules should apply:
      | Business Rule | Implementation | Impact |
      | Include all components | Ring + talk + hold + wrap-up | Complete time tracking |
      | Exclude system delays | Filter out technical issues | Accurate agent metrics |
      | Handle concurrent contacts | Proportional time allocation | Fair distribution |
    And post-processing calculations should include:
      | Post-processing Type | Duration Source | Calculation Method |
      | Wrap-up time | Agent administrative tasks | Direct measurement |
      | Relax time | Break between contacts | Optional inclusion |
      | System processing | Technical delays | Exclusion from agent metrics |

  @api_integration @calculations @service_level_metrics @critical
  Scenario: Service Level and Queue Metrics Calculations
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

  # ============================================================================
  # REAL-TIME DATA INTEGRATION
  # ============================================================================

  @api_integration @real_time @status_transmission
  Scenario: Real-time Agent Status Transmission - Event-Driven Integration
    Given external system can push real-time status changes
    When agent status changes occur in the contact center
    Then the system should receive POST requests to "/ccwfm/api/rest/status"
    With exact required parameters:
      | Field | Type | Required | Example | Validation |
      | workerId | String | Yes | "1" | Unique employee identifier |
      | stateName | String | Yes | "Technical break" | Human-readable status |
      | stateCode | String | Yes | "Break" | System status code |
      | systemId | String | Yes | "External system" | Source system identifier |
      | actionTime | Timestamp | Yes | 1568816347 | Unix timestamp |
      | action | Integer | Yes | 1 | 1=entry, 0=exit |
    And Unix timestamp format should be handled:
      | Timestamp Requirement | Implementation | Example |
      | Unix epoch format | Seconds since 1970-01-01 | 1568816347 |
      | UTC timezone | All timestamps in UTC | No timezone conversion |
      | Precision | Second-level precision | Milliseconds not required |
    And action type specification should follow:
      | Action Type | Value | Purpose | Usage |
      | Status entry | 1 | Agent enters new status | Start of status period |
      | Status exit | 0 | Agent exits current status | End of status period |
    And status event processing should be:
      | Processing Rule | Implementation | Result |
      | Event pairs | Entry + exit events | Complete status periods |
      | Immediate processing | No response required | Fire-and-forget |
      | No data integrity control | Send without confirmation | High throughput |
      | Separate events | Each status change = separate message | Fine-grained tracking |
      | Dual transmission | Exit old + enter new | Complete status transition |

  @api_integration @real_time @wfmcc_configuration @high_priority
  Scenario: WFMCC System Address Configuration for Status Transmission
    Given real-time status transmission requires target system configuration
    When configuring WFMCC system connection
    Then WFMCC system address should be configured:
      | Configuration Parameter | Format | Example | Purpose |
      | IP address | IPv4 dotted decimal | 192.168.1.100 | Target system location |
      | Port number | Integer | 8080 | Service endpoint |
      | Protocol | HTTP/HTTPS | HTTPS | Communication security |
      | Endpoint path | URL path | /ccwfm/api/rest/status | API endpoint |
    And system connectivity should be verified:
      | Verification Check | Method | Success Criteria |
      | Network connectivity | Ping test | Response received |
      | Port accessibility | TCP connection | Connection established |
      | Service availability | HTTP GET | 200 or 404 response |
      | Authentication | API test call | Valid response |
    And fallback mechanisms should be configured:
      | Fallback Scenario | Implementation | Recovery Action |
      | Network failure | Local buffering | Queue and retry |
      | Service unavailable | Circuit breaker | Temporary disable |
      | Authentication failure | Alert and log | Manual intervention |

  @api_integration @real_time @current_status_retrieval
  Scenario: Current Agent Status Retrieval - Live State Access
    Given I need current agent status information
    When I call GET /online/agentStatus with no parameters
    Then the system should return AgentOnlineStatus objects:
      | Field | Type | Required | Content | Purpose |
      | agentId | String | Yes | "1" | Agent identifier |
      | stateCode | String | Yes | "Break" | Current status code |
      | stateName | String | Yes | "Technical break" | Status description |
      | startDate | DateTime | Yes | "2020-01-01T15:25:13Z" | Current status start time |
    And response should include all currently active agents
    And status information should be real-time current state

  @api_integration @real_time @group_metrics
  Scenario: Current Group Metrics for Live Monitoring
    Given I need real-time operational monitoring data
    When I call GET /online/groupsOnlineLoad with parameters:
      | Parameter | Example | Validation |
      | groupId | "1,2" | Comma-separated group IDs |
    Then the system should return GroupOnlineLoad objects:
      | Metric Field | Type | Required | Description | Update Frequency |
      | serviceId | String | Yes | Service identifier | Static |
      | groupId | String | Yes | Group identifier | Static |
      | callNumber | Integer | Yes | Contacts in queue now | Real-time |
      | operatorNumber | Integer | Yes | Available operators | Real-time |
      | callReceived | Integer | No | Contacts received today | Hourly |
      | aht | Integer | No | Average handle time today (ms) | Every 5 minutes |
      | acd | Double | No | Percentage answered today | Hourly |
      | awt | Integer | No | Average wait time (ms) | Real-time |
      | callAnswered | Integer | No | Calls answered today | Hourly |
      | callAnsweredTst | Integer | No | Calls answered within 80/20 format | Hourly |
      | callProcessing | Integer | No | Calls being processed now | Real-time |

  # ============================================================================
  # COMPREHENSIVE ERROR HANDLING
  # ============================================================================

  @api_integration @error_handling @http_status_codes
  Scenario: Comprehensive API Error Handling - All HTTP Status Codes
    Given API endpoints are called with various conditions
    When different error scenarios occur
    Then appropriate HTTP status codes should be returned:
      | Status Code | Condition | Response Body Required | Use Case |
      | 200 | Successful operation | Yes (data) | Normal operations |
      | 400 | Bad request/validation errors | Yes (error details) | Invalid parameters |
      | 404 | No data for parameters | No body required | Empty result sets |
      | 500 | Server/processing error | Yes (error details) | System failures |
    And error responses should include structured error information:
      | Error Field | Type | Purpose | Required For |
      | field | String | Problem field identifier | 400, 500 errors |
      | message | String | Error description | All error types |
      | description | String | Detailed explanation | 400, 500 errors |

  @api_integration @error_handling @status_400_validation
  Scenario: HTTP 400 Bad Request - Validation Error Handling
    Given API endpoints receive invalid request data
    When validation errors occur
    Then status 400 should be returned with exact error structure:
      | Validation Error | Field | Message | Description |
      | Invalid date format | "startDate" | "Invalid date format" | "Date must be ISO 8601 format with timezone" |
      | Missing required parameter | "groupId" | "Required parameter missing" | "groupId parameter is required for this endpoint" |
      | Invalid data type | "step" | "Invalid data type" | "step must be positive integer in milliseconds" |
      | Out of range value | "agentId" | "Invalid agent ID" | "Agent ID not found in system" |
    And client request validation should check:
      | Validation Rule | Implementation | Error Response |
      | Required parameters | Check presence | 400 with missing field |
      | Data format | Parse and validate | 400 with format error |
      | Value ranges | Business rule check | 400 with range error |
      | Reference integrity | Foreign key validation | 400 with reference error |

  @api_integration @error_handling @status_404_no_data
  Scenario: HTTP 404 Not Found - No Data Scenarios
    Given API endpoints are called with valid parameters
    When no data exists for the specified parameters
    Then status 404 should be returned with no response body
    And 404 scenarios should include:
      | No Data Scenario | Endpoint | Condition |
      | No agents in period | /historic/agentStatusData | Period has no agent activity |
      | No calls in timeframe | /historic/serviceGroupData | Time period has no contacts |
      | No login sessions | /historic/agentLoginData | No agent logins in period |
      | Empty group metrics | /online/groupsOnlineLoad | Group has no current activity |
    And 404 should NOT be returned for:
      | Valid Empty Result | Reason |
      | Empty agent list in personnel | Empty result is valid |
      | Zero metrics in real-time | Zero values are valid data |

  @api_integration @error_handling @status_500_system_error
  Scenario: HTTP 500 Server Error - System Failure Handling
    Given API endpoints encounter system-level problems
    When server or processing errors occur
    Then status 500 should be returned with error details:
      | System Error Type | Field | Message | Description |
      | Database connection | "database" | "Database connection failed" | "Unable to connect to data source" |
      | Integration failure | "integration" | "External system error" | "Source system unavailable or timeout" |
      | Data processing | "processing" | "Data processing error" | "Unable to process request due to data issues" |
      | System overload | "capacity" | "System capacity exceeded" | "Too many concurrent requests" |
    And error logging should capture:
      | Log Information | Purpose | Retention |
      | Full request details | Debugging | 30 days |
      | Stack trace | Technical analysis | 7 days |
      | System state | Context analysis | 24 hours |
      | Performance metrics | Capacity planning | 90 days |

  # ============================================================================
  # DATA FLOW FUNCTION MAPPING
  # ============================================================================

  @api_integration @data_flow_mapping @function_transmission @integration_architecture
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

  @api_integration @data_flow_mapping @endpoint_patterns @documentation
  Scenario: REST API Endpoint URL Pattern Documentation
    Given API endpoints follow consistent URL patterns
    When documenting endpoint structure
    Then URL patterns should be documented:
      | Endpoint Category | URL Pattern | Example | Purpose |
      | Personnel data | /personnel or /agents | /agents/{startDate}/{endDate} | Employee synchronization |
      | Historical data | /historic/{dataType} | /historic/serviceGroupData | Historical metrics |
      | Real-time data | /online/{dataType} | /online/agentStatus | Current state |
      | Status transmission | /status or /ccwfm/api/rest/status | POST to WFMCC | Real-time updates |
    And HTTP method patterns should follow:
      | HTTP Method | Usage | Data Flow | Examples |
      | GET | Data retrieval | External → WFM | All historical and real-time queries |
      | POST | Data submission | WFM → External | Status transmission, data upload |
      | PUT | Data updates | Bidirectional | Configuration updates |
      | DELETE | Data removal | WFM → External | Cleanup operations |
    And parameter patterns should be consistent:
      | Parameter Type | Format | Usage | Validation |
      | Date ranges | ISO 8601 with timezone | All time-based queries | Start before end |
      | Entity IDs | Comma-separated strings | Multi-entity queries | Valid references |
      | Optional filters | Query parameters | Data filtering | Business rule validation |

  # ============================================================================
  # AUTHENTICATION AND SECURITY
  # ============================================================================

  @api_integration @security @authentication_methods
  Scenario: API Authentication and Security Implementation
    Given external systems require secure access to WFM APIs
    When authentication is configured
    Then multiple authentication methods should be supported:
      | Method | Implementation | Use Case | Security Level |
      | JWT Tokens | Bearer token in headers | Web applications | High |
      | API Keys | Key-based authentication | System integrations | Medium |
      | Basic Auth | Username/password | Simple integrations | Low |
      | OAuth 2.0 | Industry standard | Enterprise integrations | High |
    And security measures should include:
      | Security Control | Implementation | Purpose |
      | Rate limiting | Requests per minute | Prevent abuse |
      | IP whitelisting | Allowed source addresses | Network security |
      | Request logging | Complete audit trail | Security monitoring |
      | Input validation | Strict parameter checking | Injection prevention |

  @api_integration @security @authorization_roles
  Scenario: API Authorization and Role-Based Access Control
    Given different systems have different access requirements
    When API access is configured
    Then role-based permissions should control:
      | Permission Level | API Access | Data Scope |
      | Read-only | GET endpoints only | All historical data |
      | Operational | GET + POST status updates | Real-time + historical |
      | Administrative | All endpoints | Full system access |
      | Integration-specific | Custom endpoint subset | Tailored access |
    And authorization should enforce:
      | Access Rule | Implementation | Validation |
      | Endpoint permissions | Role-endpoint mapping | Check on each request |
      | Data filtering | Role-based data limits | Filter response data |
      | Time-based access | Valid access periods | Check access windows |
      | Audit requirements | Log all access attempts | Compliance tracking |

  # ============================================================================
  # PERFORMANCE AND RELIABILITY
  # ============================================================================

  @api_integration @performance @optimization_strategies
  Scenario: API Performance Optimization and Reliability
    Given high-volume API usage is expected
    When implementing performance optimization
    Then optimization strategies should include:
      | Strategy | Implementation | Expected Improvement |
      | Response caching | Redis/memory cache | 80% faster repeat queries |
      | Database optimization | Index tuning, query optimization | 50% faster database queries |
      | Connection pooling | Reuse database connections | Reduced connection overhead |
      | Compression | Gzip response compression | 70% smaller payloads |
      | Pagination | Large result set pagination | Consistent response times |
    And reliability measures should include:
      | Reliability Feature | Implementation | Purpose |
      | Circuit breaker | Fail fast on errors | Prevent cascade failures |
      | Retry logic | Exponential backoff | Handle temporary failures |
      | Health checks | Endpoint monitoring | Service availability |
      | Graceful degradation | Fallback responses | Maintain service |

  @api_integration @performance @monitoring_metrics
  Scenario: API Performance Monitoring and 80/20 Format Management
    Given API performance must meet 80/20 format service level agreements
    When monitoring API performance
    Then key metrics should be tracked:
      | Metric | Target | Alert Threshold | Purpose |
      | Response time | <2 seconds average | >5 seconds | User experience |
      | Throughput | 1000 requests/minute | <500 requests/minute | Capacity management |
      | Error rate | <1% | >5% | Reliability tracking |
      | Availability | 99.9% uptime | <99% | Service reliability |
    And 80/20 format compliance should be measured:
      | 80/20 Format Component | Measurement | Reporting |
      | Response time percentiles | 95th percentile | Daily reports |
      | Error categorization | By error type | Weekly analysis |
      | Capacity utilization | Peak usage patterns | Monthly planning |
      | Integration health | Per-system availability | Real-time dashboard |

  # ============================================================================
  # DATA VALIDATION AND QUALITY
  # ============================================================================

  @api_integration @data_validation @input_validation
  Scenario: Comprehensive API Input Validation
    Given data quality is critical for WFM operations
    When API requests are processed
    Then input validation should enforce:
      | Validation Type | Rules | Error Response |
      | Required fields | All mandatory parameters present | 400 with missing field list |
      | Data types | Correct type for each parameter | 400 with type error |
      | Format validation | DateTime, email, phone formats | 400 with format requirements |
      | Value ranges | Min/max constraints | 400 with range information |
      | Business rules | Domain-specific validation | 400 with business rule violation |
    And validation should be consistent across all endpoints:
      | Consistency Rule | Implementation | Benefit |
      | Standard error format | Same error structure | Predictable error handling |
      | Common validation logic | Reusable validators | Reduced development effort |
      | Centralized rules | Configuration-driven | Easy maintenance |

  @api_integration @data_validation @output_validation
  Scenario: API Output Data Quality Assurance
    Given response data must be accurate and complete
    When API responses are generated
    Then output validation should ensure:
      | Quality Check | Validation | Action |
      | Data completeness | All required fields present | Log missing data |
      | Value consistency | Cross-field validation | Alert on inconsistencies |
      | Format compliance | Correct data formats | Standardize output |
      | Business rule compliance | Domain validation | Flag rule violations |
    And data quality metrics should be monitored:
      | Quality Metric | Measurement | Threshold |
      | Completeness rate | % complete records | >99% |
      | Accuracy rate | % accurate values | >99.5% |
      | Consistency rate | % consistent records | >99% |
      | Timeliness | Data freshness | <5 minutes delay |

  # ============================================================================
  # INTEGRATION PATTERNS AND ARCHITECTURE
  # ============================================================================

  @api_integration @architecture @integration_patterns
  Scenario: Integration Architecture Patterns and Best Practices
    Given multiple integration patterns are supported
    When designing system integrations
    Then architecture should support these patterns:
      | Pattern | Use Case | Implementation | Benefits |
      | Event-driven | Real-time status updates | Webhook/message queue | Low latency, scalable |
      | Request-response | Historical data retrieval | REST API | Simple, reliable |
      | Batch processing | Bulk data synchronization | Scheduled jobs | Efficient for large volumes |
      | Pub-sub | Multi-system notifications | Message broker | Decoupled, flexible |
    And integration should follow best practices:
      | Best Practice | Implementation | Advantage |
      | Idempotency | Safe retry operations | Reliable processing |
      | Versioning | API version management | Backward compatibility |
      | Documentation | Complete API specs | Easy integration |
      | Testing | Automated integration tests | Quality assurance |

  @api_integration @architecture @scalability_design
  Scenario: Scalable Integration Architecture Design
    Given system must handle growing integration demands
    When designing for scalability
    Then architecture should include:
      | Scalability Feature | Implementation | Capacity |
      | Horizontal scaling | Load-balanced API servers | Linear scaling |
      | Database scaling | Read replicas, partitioning | High throughput |
      | Caching layers | Distributed cache | Reduced backend load |
      | Async processing | Message queues | High concurrency |
    And scalability should be monitored:
      | Monitoring Aspect | Metrics | Action Triggers |
      | Resource utilization | CPU, memory, I/O | Scale up/out decisions |
      | Response times | Latency percentiles | Performance optimization |
      | Queue depths | Message backlogs | Capacity adjustments |
      | Error rates | Failed operations | System health actions |

  # ============================================================================
  # COMPLIANCE AND AUDIT
  # ============================================================================

  @api_integration @compliance @audit_requirements
  Scenario: API Compliance and Audit Trail Management
    Given regulatory compliance and audit requirements exist
    When API operations are performed
    Then comprehensive audit trails should capture:
      | Audit Information | Content | Retention |
      | Request details | Full request parameters | 7 years |
      | Response data | Complete response | 7 years |
      | User identification | Authentication context | 7 years |
      | Operation timing | Request/response timestamps | 7 years |
      | Error information | Complete error details | 7 years |
    And compliance should address:
      | Compliance Area | Requirements | Implementation |
      | Data privacy | GDPR, personal data protection | Data minimization, consent |
      | Data retention | Legal retention periods | Automated archival/deletion |
      | Access control | Role-based permissions | Audit access attempts |
      | Data integrity | Tamper-proof logging | Immutable audit logs |

  @api_integration @compliance @data_protection
  Scenario: Data Protection and Privacy in API Operations
    Given personal data may be processed through APIs
    When handling employee and customer data
    Then data protection should include:
      | Protection Measure | Implementation | Purpose |
      | Data minimization | Only necessary fields | Privacy compliance |
      | Encryption in transit | TLS 1.2+ | Secure transmission |
      | Encryption at rest | Database encryption | Secure storage |
      | Access logging | Complete access records | Audit compliance |
      | Data masking | Sensitive field protection | Development/testing |
    And privacy rights should be supported:
      | Privacy Right | API Support | Implementation |
      | Data access | Personal data retrieval | GET endpoints with filtering |
      | Data correction | Update personal information | PUT/PATCH endpoints |
      | Data deletion | Remove personal data | DELETE endpoints |
      | Data portability | Export personal data | Structured data formats |

  @integration @system_management @maintenance
  Scenario: Delete integration system safely
    Given I have integration systems configured
    When I attempt to delete integration system "Old ERP"
    Then I should see safety validation:
      | Validation Type | Check | Action |
      | Active connections | Are there active API calls? | Block deletion |
      | Scheduled tasks | Are there scheduled integrations? | Block deletion |
      | Historical data | Is there integration history? | Archive instead |
      | Dependent systems | Do other systems depend on this? | Show dependencies |
    And provide cleanup procedures:
      | Step | Description | Verification |
      | Disable connections | Stop all active integrations | No active calls |
      | Archive data | Move historical data to archive | Data preserved |
      | Update dependencies | Remove references from other systems | No broken links |
      | Final deletion | Remove system configuration | System not found |

  @integration @system_management @field_editing
  Scenario: Edit integration system fields comprehensively
    Given I have integration system "Production API" configured
    When I edit system fields:
      | Field Category | Field | Current Value | New Value |
      | Basic | System Name | Production API | Production API v2 |
      | Connection | Base URL | https://api.old.com | https://api.new.com |
      | Authentication | Auth Type | Basic | OAuth2 |
      | Monitoring | Health Check | /ping | /health |
    Then field changes should be validated:
      | Field | Validation Rule | Error Response |
      | Base URL | Must be valid HTTPS URL | "Invalid URL format" |
      | Auth Type | Must be supported method | "Authentication method not supported" |
      | Health Check | Must respond with 200 OK | "Health check endpoint unreachable" |
    And changes should be applied atomically
    And rollback should be available if validation fails

