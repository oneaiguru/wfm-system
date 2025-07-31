Feature: Argus WFM System Architecture
  As a system analyst
  I want to understand the dual system architecture
  So that I can properly test both administrative and employee functions

  Background:
    Given the Argus WFM system has two main components:
      | Component | URL | Purpose |
      | Administrative System | https://cc1010wfmcc.argustelecom.ru/ccwfm/ | Backend management and configuration |
      | Employee Portal | https://lkcc1010wfmcc.argustelecom.ru/login | Employee self-service functions |

  # VERIFIED: 2025-07-27 - Real Argus admin portal fully accessed and documented
  # REALITY: Admin portal at cc1010wfmcc with Konstantin/12345 credentials
  # REALITY: Dashboard shows 9 main categories with Russian interface
  # REALITY: Personnel stats display: 513 employees, 19 groups, 9 services
  Scenario: Access Administrative System with Multi-Language Support
    Given I navigate to "https://cc1010wfmcc.argustelecom.ru/ccwfm/"
    When I login with credentials "Konstantin/12345"
    Then I should see the dashboard with title "Домашняя страница"
    And I should see user greeting format with "K F" (Konstantin)
    And I should see dashboard statistics:
      | Metric | Value |
      | Службы (Services) | 9 |
      | Группы (Groups) | 19 |
      | Сотрудники (Employees) | 513 |
    # VERIFIED: 2025-07-27 - Complete menu structure documented from real Argus
    # REALITY: 9 main categories with extensive submenus as documented
    And I should see navigation options:
      | Option | Key Submenu Items |
      | Мой кабинет | Personal profile and settings |
      | Заявки | Employee request management |
      | Персонал | Сотрудники, Группы, Службы, Структура групп, Подразделения |
      | Справочники | Правила работы, Роли, Должности, Производственный календарь |
      | Прогнозирование | Просмотр нагрузки, Спрогнозировать нагрузку, Импорт прогнозов |
      | Планирование | Актуальное расписание, Создание расписаний, Мультискильное планирование |
      | Мониторинг | Оперативный контроль, Статусы операторов, Биржа |
      | Отчёты | Список отчётов, Редактор отчётов, Соблюдение расписания |
    # ARGUS ACTUAL: Top bar contains notifications, profile, language
    And the top navigation bar should contain:
      | Element | Description | Our Status |
      | Notifications | Shows count of unread | Missing |
      | Profile dropdown | User name with submenu | Partial |
      | Language switcher | Russian/English toggle | Missing |
      | Logout | Выход из системы | Exists |

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

  # R4-INTEGRATION-REALITY: SPEC-081 Multi-Site Management Integration
  # Status: ⚠️ PARTIALLY VERIFIED - Basic multi-site support found
  # Evidence: 4 timezones visible in system (UTC+2 to UTC+5)
  # Reality: Site management exists but no external site sync APIs
  # Architecture: Internal multi-site configuration only
  # @verified-limited - Multi-site exists but no integration
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
