 # REALITY: 2025-07-27 - Complete agent activity monitoring system for work time efficiency tracking  
 # Database includes: agent_activity tables (monthly partitioned), agent_current_status, agents
 # Time categories: ready_time, not_ready_time, talk_time, hold_time, wrap_time for productivity classification
 # Performance metrics: calls_handled, calls_transferred, login_time for efficiency calculations
 # Active agents: 5 agents (AGENT_1 to AGENT_5) with shift schedules and group assignments
 # Real-time tracking: current_status, status_since, last_state_change for monitoring
 # R4-INTEGRATION-REALITY: SPEC-110 Work Time Efficiency Integration
 # Status: ❌ NO EXTERNAL INTEGRATION - Internal productivity tracking
 # Evidence: Agent activity monitoring is internal database feature
 # Reality: No external time tracking systems integrated
 # Architecture: Internal agent_activity tables only
 # @integration-not-applicable - Internal productivity feature
 @work_time_efficiency @productivity_monitoring @critical
 Feature: Work Time Efficiency Configuration
   As a system administrator
   I want to configure work time efficiency parameters
   So that operator productivity can be properly monitored and calculated
 
   Background:
     Given I am authenticated as administrator
     And the work time efficiency system is available
 
   @status_configuration @operator_states
   Scenario: Work status parameter configuration
     # R4-INTEGRATION-REALITY: SPEC-028 Work Time Efficiency Testing
     # Status: ✅ INDIRECTLY VERIFIED - Menu shows efficiency configuration
     # Context: "Конфигурация эффективности рабочего времени" in Справочники
     # Evidence: Work time efficiency configuration confirmed in menu structure
     # Navigation: Справочники → Конфигурация эффективности рабочего времени
     # @verified-menu-visible - Work time efficiency configuration exists
     Given I need to configure operator work statuses
     When I define work status parameters
     Then the system should support status types:
       | Status Type | Code | Description | Productivity |
       | Available | AVL | Ready for calls | Productive |
       | In Call | CALL | Handling customer | Productive |
       | After Call Work | ACW | Post-call processing | Productive |
       | Break | BRK | Rest period | Non-productive |
       | Lunch | LUN | Lunch break | Non-productive |
       | Training | TRN | Training session | Productive |
       | Meeting | MTG | Team meeting | Productive |
       | Offline | OFF | Not available | Non-productive |
     And each status should have parameters:
       | Parameter | Type | Purpose | Default |
       | Productive time | Boolean | Counts toward productivity | true |
       | Net load | Boolean | Counts toward net load | false |
       | Talk time | Boolean | Counts as talk time | false |
       | Break time | Boolean | Counts as break | false |
       | Actual timesheet | Boolean | Counts in timesheet | true |
