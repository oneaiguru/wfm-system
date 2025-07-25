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
