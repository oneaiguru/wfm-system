 @special_events @forecasting @load_coefficients @critical
 Feature: Special Events for Forecasting
   As a workforce planner
   I want to configure special events that affect load forecasting
   So that demand predictions account for unforecastable events
 
   Background:
     Given I am authenticated as planner
     And the special events forecasting system is available
 
   @unforecastable_events @event_configuration
   Scenario: Unforecastable events configuration
     Given I need to configure special events for forecasting
     When I create a new special event
     Then the system should support event types:
       | Event Type | Description | Impact | Examples |
       | City Holiday | Local holiday | Load reduction | City Day |
       | Mass Event | Large gathering | Load increase | Concert, Sports |
       | Weather Event | Severe weather | Load variation | Storm, Snow |
       | Technical Event | System outage | Load spike | Service disruption |
       | Marketing Event | Promotion campaign | Load increase | Sale announcement |
     And event configuration parameters:
       | Parameter | Type | Required | Purpose |
       | Event name | String | Yes | Identification |
       | Event type | Enum | Yes | Categorization |
       | Start date | Date | Yes | Event beginning |
       | End date | Date | Yes | Event conclusion |
       | Load coefficient | Decimal | Yes | Impact multiplier |
       | Service groups | Array | Yes | Affected services |
