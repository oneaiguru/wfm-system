Feature: Argus WFM System Architecture
  As a system analyst
  I want to understand the dual system architecture
  So that I can properly test both administrative and employee functions

  Background:
    Given the Argus WFM system has two main components:
      | Component | URL | Purpose |
      | Administrative System | https://cc1010wfmcc.argustelecom.ru/ccwfm/ | Backend management and configuration |
      | Employee Portal | https://lkcc1010wfmcc.argustelecom.ru/login | Employee self-service functions |

  Scenario: Access Administrative System
    Given I navigate to "https://cc1010wfmcc.argustelecom.ru/ccwfm/"
    When I login with credentials "test/test"
    Then I should see the dashboard with title "Домашняя страница"
    And I should see user greeting "Здравствуйте, Юрий Артёмович!"
    And I should see personal information for user ID "111538"
    And I should see navigation options:
      | Option |
      | Домашняя страница |
      | Мой кабинет |
      | Мой профиль |
      | О системе |
      | Выход из системы |

  Scenario: Limited Permissions in Administrative System
    Given I am logged into the administrative system as "test/test"
    When I examine available navigation options
    Then I should NOT see administrative functions:
      | Missing Function |
      | Справочники |
      | Трудовые нормативы |
      | Calendar management |
      | User administration |
    And I should only have access to personal information views

  Scenario: Employee Portal Access Requirements
    Given I attempt to access "https://lkcc1010wfmcc.argustelecom.ru/"
    Then the system should be accessible for employee functions:
      | Function |
      | Календарь |
      | Заявки |
      | Shift management |
      | Request creation |
    But access may require:
      | Requirement |
      | Internal network access |
      | Different authentication method |
      | Specific user permissions |

  @multi_site_management @location_hierarchy @enterprise_architecture
  Scenario: Configure Multi-Site Location Management with Hierarchy Support
    Given I need to manage multiple site locations with independent operations
    When I configure multi-site location architecture
    Then I should define location hierarchy structure:
      | Level | Location Type | Examples | Management Scope |
      | 1 | Corporate | Headquarters | Global policies |
      | 2 | Regional | Regional offices | Regional coordination |
      | 3 | City | City branches | Local operations |
      | 4 | Site | Individual locations | Site-specific activities |
    And configure location properties:
      | Property | Configuration Options | Purpose | Validation |
      | Location Name | Unique identifier | Site identification | No duplicates |
      | Address | Full physical address | Geographic location | Valid address format |
      | Timezone | Regional timezone | Schedule coordination | Valid timezone codes |
      | Operating Hours | Site-specific hours | Operational windows | Logical time ranges |
      | Capacity | Maximum employees | Resource planning | Positive numbers |
      | Status | Active/Inactive/Maintenance | Operational state | Valid status codes |
    And implement location-specific business rules:
      | Business Rule | Implementation | Purpose | Enforcement |
      | Schedule Coordination | Cross-site schedule sync | Multi-site operations | Automatic timezone conversion |
      | Resource Sharing | Inter-site resource allocation | Efficiency optimization | Approval workflows |
      | Reporting Aggregation | Hierarchical data rollup | Management reporting | Data consistency validation |
      | Security Isolation | Site-based access control | Data protection | Role-based permissions |
    And configure location synchronization:
      | Sync Type | Frequency | Data Elements | Conflict Resolution |
      | Real-time Events | Immediate | Status changes, alerts | Timestamp-based priority |
      | Schedule Updates | Every 15 minutes | Shift changes, coverage | Business rules validation |
      | Reporting Data | Hourly | Performance metrics | Master site aggregation |
      | Configuration Changes | On-demand | Policy updates | Hierarchical inheritance |
    And set up location-specific reporting:
      | Report Type | Scope | Frequency | Recipients |
      | Site Performance | Individual site | Daily | Site managers |
      | Regional Summary | Regional rollup | Weekly | Regional managers |
      | Corporate Dashboard | All sites | Real-time | Executive team |
      | Comparative Analysis | Cross-site comparison | Monthly | Operations directors |
