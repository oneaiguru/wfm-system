 # Language: en
 # Mass Assignment Operations Feature
 # This file contains BDD scenarios for mass assignment operations
 # including business rules, vacation schemes, and work hours
 
 Feature: Mass Assignment Operations
   As a WFM Administrator
   I want to perform mass assignment operations
   So that I can efficiently manage large numbers of employees
 
   Background:
     Given I am logged in as an administrator
     And I have access to mass assignment operations
     And employee data is available for assignment
 
   @mass_assignment @business_rules @critical
   Scenario: Mass business rules assignment with filtering
     Given I navigate to mass assignment page
     When I select "Business Rules" assignment type
     And I apply employee filters:
       | Filter Type | Value | Description |
       | Department | "Customer Service" | Target department |
       | Employee Type | "Office" | Office operators only |
       | Status | "Active" | Active employees only |
     Then I should see filtered employee list
     And I should see employee count: "25 employees selected"
     When I select business rule "Standard Lunch Break"
     And I click "Apply to Selected"
     Then I should see confirmation dialog
     And I should see assignment preview:
       | Employee | Current Rule | New Rule | Status |
       | John Doe | No Rule | Standard Lunch Break | Will Apply |
       | Jane Smith | Custom Rule | Standard Lunch Break | Will Override |
     When I confirm the assignment
     Then I should see success message: "Business rules assigned to 25 employees"
     And all selected employees should have the new business rule applied
 
   @mass_assignment @vacation_schemes @critical
   Scenario: Mass vacation schemes assignment with validation
     Given I navigate to mass assignment page
     When I select "Vacation Schemes" assignment type
     And I apply employee filters:
       | Filter Type | Value | Description |
       | Group | "Technical Support" | Target group |
       | Segment | "Senior" | Senior employees |
     Then I should see filtered employee list with vacation scheme compatibility
     When I select vacation scheme "Standard Annual Leave"
     And I configure scheme parameters:
       | Parameter | Value | Description |
       | Minimum Time Between Vacations | 30 days | Minimum interval |
       | Maximum Vacation Shift | 7 days | Flexibility limit |
       | Multiple Schemes Allowed | Yes | Allow multiple schemes |
     Then I should see validation results:
       | Employee | Current Scheme | Compatibility | Status |
       | Alice Johnson | Basic Scheme | Compatible | Ready |
       | Bob Wilson | Premium Scheme | Conflict | Requires Override |
     When I confirm the assignment with overrides
     Then I should see success message: "Vacation schemes assigned to 15 employees"
     And all employees should have the new vacation scheme configured
 
   @mass_assignment @work_hours @critical
   Scenario: Mass work hours assignment for reporting periods
     Given I navigate to mass assignment page
     When I select "Work Hours" assignment type
     And I configure assignment parameters:
       | Parameter | Value | Description |
       | Assignment Period | 2024 Q1 | Target period |
       | Hours Source | Manual | Manual assignment |
       | Department | "Call Center" | Target department |
     Then I should see work hours assignment interface
     When I specify work hours by period:
       | Period | Start Date | End Date | Work Hours | Description |
       | January 2024 | 2024-01-01 | 2024-01-31 | 168 | Standard month |
       | February 2024 | 2024-02-01 | 2024-02-29 | 160 | Leap year adjustment |
       | March 2024 | 2024-03-01 | 2024-03-31 | 176 | Extended month |
     And I select employees for assignment:
       | Employee | Department | Current Hours | New Hours | Status |
       | Employee 1 | Call Center | 170 | 168 | Will Update |
       | Employee 2 | Call Center | 165 | 160 | Will Update |
     When I confirm the work hours assignment
     Then I should see success message: "Work hours assigned to 20 employees"
     And all selected employees should have updated work hours for the period
 
   @mass_assignment @filtering @high
   Scenario: Employee list filtering for mass assignment
     Given I navigate to mass assignment page
     When I access employee filtering interface
     Then I should see filtering options:
       | Filter Type | Options | Description |
       | Department | All departments | Department filter |
       | Employee Type | Office, Remote, Mixed | Work location |
       | Status | Active, Inactive, All | Employment status |
       | Group | All groups | Functional groups |
       | Segment | All segments | Employee segments |
     When I apply multiple filters:
       | Filter Type | Value | Description |
       | Department | "Customer Service" | Target department |
       | Employee Type | "Office" | Office workers only |
       | Status | "Active" | Active employees |
     Then I should see filtered results:
       | Employee | Department | Type | Status | Eligible |
       | John Doe | Customer Service | Office | Active | Yes |
       | Jane Smith | Customer Service | Office | Active | Yes |
     And I should see employee count: "25 employees match filters"
     When I search by surname: "Smith"
     Then I should see search results:
       | Employee | Personnel Number | Department | Match |
       | Jane Smith | 12345 | Customer Service | Name |
       | Bob Smith | 67890 | Technical Support | Name |
     And I should be able to select employees for mass assignment
