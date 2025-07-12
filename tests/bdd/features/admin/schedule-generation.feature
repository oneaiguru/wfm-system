Feature: Schedule Generation
  As a manager
  I want to generate optimized schedules
  So that I can ensure proper coverage while respecting employee constraints

  Background:
    Given I am logged in as a manager
    And the following employees exist:
      | name        | skills          | max_hours | preferred_shifts |
      | John Doe    | sales,support   | 40        | morning         |
      | Jane Smith  | support         | 35        | evening         |
      | Bob Johnson | sales           | 40        | any             |
      | Alice Brown | sales,support   | 30        | morning         |
    And the following labor standards are configured:
      | day       | hour | sales_required | support_required |
      | Monday    | 08   | 2             | 1               |
      | Monday    | 09   | 3             | 2               |
      | Monday    | 10   | 3             | 2               |
      | Monday    | 11   | 4             | 2               |
      | Monday    | 12   | 4             | 3               |
      | Monday    | 13   | 3             | 2               |
      | Monday    | 14   | 3             | 2               |
      | Monday    | 15   | 3             | 1               |
      | Monday    | 16   | 2             | 1               |

  Scenario: Generate schedule with basic requirements
    When I create a new schedule for "2024-01-01" to "2024-01-07"
    And I select all available employees
    And I set the optimization goal to "balanced coverage"
    And I generate the schedule
    Then the schedule should be created successfully
    And all labor standard requirements should be met
    And no employee should work more than their maximum hours
    And the coverage percentage should be at least 95%

  Scenario: Generate schedule with employee preferences
    When I create a new schedule for "2024-01-01" to "2024-01-07"
    And I enable "respect employee preferences" option
    And I generate the schedule
    Then employees with morning preference should have mostly morning shifts
    And employees with evening preference should have mostly evening shifts
    And preference satisfaction rate should be above 80%

  Scenario: Handle insufficient staffing
    Given only 2 employees are available
    When I create a new schedule for "2024-01-01" to "2024-01-07"
    And I generate the schedule
    Then I should see a warning about insufficient staffing
    And the schedule should show coverage gaps
    And the system should suggest hiring recommendations:
      | skill   | additional_needed |
      | sales   | 2                |
      | support | 1                |

  Scenario: Generate schedule with constraints
    When I create a new schedule for "2024-01-01" to "2024-01-07"
    And I add the following constraints:
      | constraint_type        | value |
      | max_consecutive_days   | 5     |
      | min_hours_between_shifts | 11    |
      | max_shift_length       | 10    |
      | min_shift_length       | 4     |
    And I generate the schedule
    Then all shifts should respect the defined constraints
    And no employee should work more than 5 consecutive days
    And all shifts should be between 4 and 10 hours

  Scenario: Optimize for minimal labor cost
    When I create a new schedule for "2024-01-01" to "2024-01-07"
    And I set the optimization goal to "minimize cost"
    And I set overtime threshold to 40 hours
    And I generate the schedule
    Then the total labor cost should be minimized
    And overtime hours should be less than 5% of total hours
    And senior employees should not be over-scheduled

  Scenario: Generate schedule with pre-assigned shifts
    Given the following shifts are pre-assigned:
      | employee   | date       | start | end   |
      | John Doe   | 2024-01-01 | 08:00 | 16:00 |
      | Jane Smith | 2024-01-01 | 16:00 | 00:00 |
    When I create a new schedule for "2024-01-01" to "2024-01-07"
    And I lock the pre-assigned shifts
    And I generate the schedule
    Then the pre-assigned shifts should remain unchanged
    And the remaining shifts should be optimally distributed
    
  Scenario: Multi-skill optimization
    When I create a new schedule for "2024-01-01" to "2024-01-07"
    And I enable "multi-skill optimization"
    And I generate the schedule
    Then employees with multiple skills should be efficiently utilized
    And skill coverage should be balanced throughout the day
    And no skill should have less than 90% coverage

  Scenario Outline: Generate schedules for different patterns
    When I create a new schedule for "2024-01-01" to "2024-01-07"
    And I select the "<pattern>" scheduling pattern
    And I generate the schedule
    Then the schedule should follow the "<pattern>" pattern
    And all employees should have consistent shift patterns

    Examples:
      | pattern      |
      | 4-on-3-off   |
      | 5-on-2-off   |
      | rotating     |
      | continental  |

  Scenario: Real-time schedule adjustments
    Given a schedule has been generated for next week
    When an employee calls in sick for "2024-01-03"
    And I use the "auto-adjust" feature
    Then the system should find a suitable replacement
    And the replacement should have the required skills
    And the adjustment should maintain coverage requirements
    And affected employees should be notified immediately