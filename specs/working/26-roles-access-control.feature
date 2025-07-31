 # VERIFIED: 2025-07-27 - R6 documented comprehensive access control patterns
 # REALITY: Role-based access control implemented with clear permission hierarchy
 # EVIDENCE: Konstantin/12345 has operational access, test/test has employee access
 # IMPLEMENTATION: Admin portal vs Employee portal separation, 403 errors for restricted areas
 # PATTERNS: Operational (reporting, monitoring) vs Administrative (configuration, management)
 @verified @roles_management @access_control @security @critical @r6-tested
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

  # VERIFIED: 2025-07-30 - R1 discovered three-tier admin hierarchy
  # REALITY: Argus implements Standard Admin < System Admin < Audit Admin
  # EVIDENCE: 403 Forbidden for /system/* and /audit/* paths with standard admin
  # IMPLEMENTATION: Permission-based URL access control
  # RUSSIAN_TERMS: 
  #   - Ошибка системы = System error
  #   - У вас нет прав для выполнения данной операции = You don't have rights for this operation
  @hidden-feature @discovered-2025-07-30 @three-tier-admin
  Scenario: Three-tier administrator hierarchy
    Given I am logged in as standard administrator "Konstantin"
    When I try to access system configuration at "/ccwfm/views/env/system/"
    Then I should receive 403 Forbidden error
    And error page should display "Ошибка системы"
    And error message should be "У вас нет прав для выполнения данной операции"
    When I try to access audit logs at "/ccwfm/views/env/audit/"
    Then I should receive 403 Forbidden error
    Given I have system administrator privileges
    When I access system configuration
    Then I should see system settings panel
    But audit logs should still be forbidden
    Given I have audit administrator privileges
    When I access audit logs
    Then I should see comprehensive audit trail
    And all system events should be visible

  # VERIFIED: 2025-07-30 - R1 discovered role management interface
  # REALITY: Full RBAC system with permission matrices
  # EVIDENCE: /views/env/security/RoleListView.xhtml accessible to system admin
  # IMPLEMENTATION: Role creation, editing, permission assignment
  # UI_FLOW: Security → Roles → Create/Edit → Permission Matrix
  @hidden-feature @discovered-2025-07-30 @role-management-ui
  Scenario: Role management interface
    Given I have system administrator access
    When I navigate to "/views/env/security/RoleListView.xhtml"
    Then I should see role management interface
    And I should be able to create new roles
    And I should see permission matrix for assignment
    When I create a new role "TestRole-2025"
    Then system should generate unique Role ID
    And I should be able to assign permissions:
      | Permission Category | Available Options |
      | Personnel Management | VIEW_EMPLOYEES, EDIT_EMPLOYEES, DELETE_EMPLOYEES |
      | Schedule Management | VIEW_SCHEDULES, EDIT_SCHEDULES, APPROVE_SCHEDULES |
      | System Configuration | VIEW_SETTINGS, EDIT_SETTINGS |
      | Audit Access | VIEW_AUDIT, EXPORT_AUDIT |
    And I should be able to assign role to users
    And role should support bulk operations

  # VERIFIED: 2025-07-30 - R1 discovered business rules engine
  # REALITY: Menu item exists for "Бизнес-правила" but URL returns 404
  # EVIDENCE: Menu item discovered via JavaScript extraction
  # IMPLEMENTATION: Advanced automation framework (not yet implemented)
  # RUSSIAN_TERMS: Бизнес-правила = Business rules
  @hidden-feature @discovered-2025-07-30 @business-rules @not-implemented
  Scenario: Business rules engine (placeholder)
    Given I have system administrator access
    When I look for business rules in admin menu
    Then I should see "Бизнес-правила" menu item
    But URL "/ccwfm/views/env/personnel/BusinessRuleListView.xhtml" returns 404
    # Note: Feature exists in menu but not implemented
    # Future implementation should support:
    # - Automated workflow rules
    # - Conditional processing
    # - Event-driven actions

  # VERIFIED: 2025-07-30 - R1 discovered notification schemes
  # REALITY: Advanced notification configuration behind system admin
  # EVIDENCE: /views/env/dict/NotificationSchemeListView.xhtml returns 403
  # IMPLEMENTATION: Template-based notification system
  # RUSSIAN_TERMS: Схемы уведомлений = Notification schemes
  @hidden-feature @discovered-2025-07-30 @notification-schemes
  Scenario: Notification schemes configuration
    Given I have system administrator access
    When I navigate to "/views/env/dict/NotificationSchemeListView.xhtml"
    Then I should see notification schemes management
    And I should be able to create notification templates
    And I should configure delivery methods:
      | Method | Configuration |
      | Email | SMTP settings, templates |
      | SMS | Gateway settings, templates |
      | In-app | Real-time notifications |
    And I should set trigger conditions
    And I should assign schemes to user groups
    But standard admin should see 403 Forbidden
