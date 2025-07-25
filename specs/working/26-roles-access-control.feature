 @roles_management @access_control @security @critical
 Feature: Roles and Access Rights Management
   As a system administrator
   I want to manage user roles and access rights
   So that system security and permissions are properly controlled
 
   Background:
     Given I am authenticated as administrator
     And the roles management system is available
 
   @system_roles @built_in_roles
   Scenario: System roles configuration
     Given the system has built-in roles
     When I view the roles reference
     Then the system should display default roles:
       | Role Name | Description | Permissions | Default |
       | Administrator | Full system access | ALL | No |
       | Senior Operator | Advanced operations | PLANNING,REPORTING,MONITORING | No |
       | Operator | Basic operations | REQUESTS,PERSONAL_CABINET | Yes |
     And each role should have defined permissions:
       | Permission Category | Administrator | Senior Operator | Operator |
       | User Management | Full | None | None |
       | System Configuration | Full | None | None |
       | Planning | Full | Full | None |
       | Reporting | Full | Full | View Only |
       | Monitoring | Full | Full | Personal Only |
 
   @business_roles @custom_roles
   Scenario: Business role creation
     Given I want to create a custom business role
     When I create a new role with details:
       | Field | Type | Value | Purpose |
       | Role name | String | "Quality Manager" | Role identification |
       | Description | Text | "Quality control access" | Role purpose |
       | Active | Boolean | true | Role status |
       | Default | Boolean | false | Auto-assignment |
     Then the system should validate the role:
       | Validation Type | Rule | Error Message |
       | Name uniqueness | Unique per system | "Role name exists" |
       | Name length | 3-50 characters | "Invalid name length" |
       | Description | 0-500 characters | "Description too long" |
     And save the role to the database
 
   @access_rights @permission_assignment
   Scenario: Access rights assignment to roles
     Given I have a business role "Quality Manager"
     When I assign access rights to the role
     Then I should be able to select permissions:
       | Permission Group | Available Rights | Selection Type |
       | Personnel Management | VIEW,EDIT,DELETE | Multiple |
       | Planning | VIEW,EDIT,APPROVE | Multiple |
       | Reporting | VIEW,EXPORT,SCHEDULE | Multiple |
       | System Configuration | VIEW,EDIT | Multiple |
     And the system should validate assignments:
       | Validation | Rule | Response |
       | Permission conflicts | No contradictions | "Conflicting permissions" |
       | Minimum access | At least LOGIN | "Insufficient permissions" |
       | Maximum access | Not exceed Administrator | "Excessive permissions" |
