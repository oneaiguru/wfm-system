# System Architecture - Detailed BDD Analysis & Spec Updates

## Current BDD Spec Review
**File**: `/project/specs/working/01-system-architecture.feature`
**Scenarios Analyzed**: Lines 12-86

## Scenario 1: Access Administrative System (Lines 12-24)

### Current BDD Spec (Too Generic):
```gherkin
Scenario: Access Administrative System
  Given I navigate to the administrative system URL
  When I enter valid credentials
  Then I should see the dashboard with title and user greeting
  And navigation options should be available
```

### DETAILED BDD SPEC UPDATE NEEDED:
```gherkin
Scenario: Multi-Language Administrative System Login with Role-Based Dashboard
  Given I am on the WFM administrative login page
  And the system supports Russian and English languages
  And I have the following credentials:
    | username   | password | role        | full_name       | language |
    | Konstantin | 12345    | Admin       | Konstantin F    | Russian  |
    | admin      | password | Admin       | Administrator   | English  |
    | manager7   | test     | Manager     | John Manager    | English  |
    | employee1  | test     | Employee    | John Smith      | English  |
  
  When I enter username "Konstantin" in the login field
  And I enter password "12345" in the password field
  And I click the "Войти" button
  
  Then I should be redirected to the dashboard
  And I should see a personalized greeting "Здравствуйте, Konstantin F!"
  And the page title should be "Домашняя страница"
  And I should see the following navigation menu structure:
    | Menu Item        | Russian Label      | Submenu Items                                    |
    | My Cabinet       | Мой кабинет       | None                                            |
    | Requests         | Заявки            | None                                            |
    | Personnel        | Персонал          | Сотрудники, Группы, Службы, Структура групп     |
    | References       | Справочники       | Правила работы, Предпочтения, Мероприятия       |
    | Forecasting      | Прогнозирование   | Просмотр нагрузки, Спрогнозировать нагрузку    |
    | Planning         | Планирование      | Актуальное расписание, Корректировка графиков   |
    | Monitoring       | Мониторинг        | Управление группами, Оперативный контроль       |
    | Reports          | Отчёты            | Редактор отчётов, Список отчётов                |
  
  And I should see the following dashboard statistics:
    | Metric       | Value | Russian Label |
    | Services     | 9     | Службы        |
    | Groups       | 19    | Группы        |
    | Employees    | 513   | Сотрудники    |
  
  And the top bar should contain:
    | Element              | Location  | Functionality                    |
    | Notifications icon   | Top right | Shows unread count (0)          |
    | Profile dropdown     | Top right | Contains "Мой профиль"          |
    | About system menu    | Top right | Links to error report, about    |
    | Language switcher    | Top right | Russian/English toggle          |
    | Logout button        | Top right | "Выход из системы"              |

  When I click on the language switcher and select "English"
  Then the interface language should change to English
  And the greeting should update to "Hello, Konstantin F!"
  And all menu items should display in English
```

### OUR IMPLEMENTATION GAPS:

1. **Authentication Issues**:
   - ❌ Auto-redirects to dashboard without login
   - ❌ No proper credential validation
   - ❌ Missing role-based redirects

2. **Post-Login Display**:
   - ❌ Generic "Welcome, John Doe" instead of proper greeting format
   - ❌ No user full name display
   - ❌ Missing language switcher

3. **Navigation Structure**:
   - ✅ Has navigation menu
   - ❌ Flat structure instead of hierarchical with submenus
   - ❌ Different menu items than Argus
   - ❌ No Russian language support

4. **Dashboard Content**:
   - ❌ Shows generic KPIs instead of organizational stats
   - ❌ Missing quick access tiles from Argus
   - ❌ No notification system

### PARITY SCORE: 30%

## Scenario 2: Configure Multi-Site Location Management (Lines 52-86)

### Current BDD Spec (Insufficient Detail):
```gherkin
Scenario: Configure Multi-Site Location Management
  Given I have administrator permissions
  When I navigate to location configuration
  Then I can configure location hierarchy
```

### DETAILED BDD SPEC UPDATE NEEDED:
```gherkin
Scenario: Hierarchical Multi-Site Location Configuration with Time Zones
  Given I am logged in as a system administrator
  And I navigate to "Справочники" > "Подразделения"
  
  When I click "Создать новое подразделение"
  Then I should see a location creation form with:
    | Field                | Type       | Required | Validation                           |
    | Location Name        | Text       | Yes      | Unique across system                 |
    | Location Type        | Dropdown   | Yes      | Corporate/Regional/City/Site         |
    | Parent Location      | Dropdown   | No       | Only higher-level types available    |
    | Address Line 1       | Text       | Yes      | Max 100 characters                   |
    | Address Line 2       | Text       | No       | Max 100 characters                   |
    | City                 | Text       | Yes      | Max 50 characters                    |
    | State/Region         | Text       | Yes      | Max 50 characters                    |
    | Postal Code          | Text       | Yes      | Format validation by country         |
    | Country              | Dropdown   | Yes      | ISO country list                     |
    | Time Zone            | Dropdown   | Yes      | IANA timezone database               |
    | Business Hours Start | Time       | Yes      | 24-hour format                       |
    | Business Hours End   | Time       | Yes      | Must be after start time             |
    | Capacity             | Number     | Yes      | Positive integer                     |
    | Status               | Toggle     | Yes      | Active/Inactive                      |

  When I create a location hierarchy:
    | Name               | Type       | Parent            | Time Zone           | Hours      | Capacity |
    | ACME Corporation   | Corporate  | -                 | America/New_York    | 00:00-23:59| 5000     |
    | Eastern Region     | Regional   | ACME Corporation  | America/New_York    | 08:00-20:00| 2000     |
    | New York Office    | City       | Eastern Region    | America/New_York    | 08:00-18:00| 500      |
    | NYC Call Center 1  | Site       | New York Office   | America/New_York    | 07:00-23:00| 150      |
    | NYC Call Center 2  | Site       | New York Office   | America/New_York    | 14:00-06:00| 100      |

  Then the location hierarchy should be displayed as a tree:
    """
    ▼ ACME Corporation (Corporate)
      ▼ Eastern Region (Regional) 
        ▼ New York Office (City)
          ├─ NYC Call Center 1 (Site) - 150 seats
          └─ NYC Call Center 2 (Site) - 100 seats
    """

  And each location should show:
    | Information          | Display Format                    |
    | Current Local Time   | Based on configured timezone      |
    | Total Employees      | Aggregated from child locations   |
    | Active Employees     | Real-time count                   |
    | Utilization Rate     | Active/Capacity percentage        |

  When I configure location-specific business rules for "NYC Call Center 1":
    | Rule Type            | Configuration                     |
    | Min Staff Coverage   | 20% of capacity always            |
    | Max Consecutive Days | 6 days                           |
    | Overtime Threshold   | 40 hours/week                     |
    | Break Requirements   | 15 min per 4 hours               |
    | Lunch Duration       | 30 min unpaid after 6 hours      |

  Then these rules should override global rules for employees at this location
  
  When I enable cross-location synchronization
  Then the system should:
    - Sync employee schedules across locations every 15 minutes
    - Handle timezone conversions automatically
    - Prevent scheduling conflicts for shared employees
    - Generate consolidated reports across all locations
```

### OUR IMPLEMENTATION GAPS:

1. **Location Management**:
   - ❌ No location/site configuration UI
   - ❌ No hierarchical structure support
   - ❌ Missing timezone handling

2. **Business Rules**:
   - ❌ No location-specific rule configuration
   - ❌ No rule inheritance system
   - ❌ Missing validation framework

3. **Multi-Site Features**:
   - ❌ No cross-location synchronization
   - ❌ No consolidated reporting
   - ❌ Missing capacity management

### PARITY SCORE: 0% (Feature not implemented)

## Scenario 3: Role-Based Access Control (Not in original spec - NEEDS ADDITION)

### NEW BDD SPEC TO ADD:
```gherkin
Scenario: Granular Role-Based Access Control with Custom Permissions
  Given I am logged in as a system administrator
  And I navigate to "Справочники" > "Роли"
  
  When I view the system roles list
  Then I should see predefined roles:
    | Role Name           | Russian Name          | Permission Level | User Count |
    | System Admin        | Системный админ       | Full Access      | 2          |
    | Operations Manager  | Менеджер операций     | Department       | 15         |
    | Team Supervisor     | Супервизор           | Team             | 45         |
    | Senior Agent        | Старший оператор      | Self + Coaching  | 120        |
    | Agent               | Оператор             | Self Only        | 331        |
    
  When I create a custom role "Schedule Coordinator"
  Then I should see a permission matrix with modules:
    | Module              | View | Create | Edit | Delete | Approve |
    | Employee Schedules  | ✓    | ✓      | ✓    | ✗      | ✓       |
    | Vacation Requests   | ✓    | ✗      | ✗    | ✗      | ✓       |
    | Shift Templates     | ✓    | ✓      | ✓    | ✓      | ✗       |
    | Reports             | ✓    | ✗      | ✗    | ✗      | ✗       |
    | Forecasting         | ✓    | ✗      | ✗    | ✗      | ✗       |
    
  And I can set data access scope:
    | Scope Option        | Description                              |
    | All Locations       | Access to entire organization            |
    | Assigned Locations  | Only locations user is assigned to       |
    | Managed Teams       | Only teams under user's management       |
    | Own Data            | Only user's personal information         |
```

### OUR IMPLEMENTATION:
- ✅ Basic role detection (Admin, Manager, Employee)
- ❌ No role configuration UI
- ❌ No granular permissions
- ❌ No custom roles

### PARITY SCORE: 15%

## Overall System Architecture Recommendations

### Critical Updates Needed for BDD Specs:
1. Add 5-10 more scenarios for complete system architecture coverage
2. Include error handling scenarios
3. Add performance requirements
4. Specify API response formats
5. Include security scenarios (session timeout, concurrent login, etc.)

### Implementation Priority:
1. **Fix authentication flow** - Currently broken
2. **Add proper user greeting and profile display**
3. **Implement hierarchical navigation**
4. **Add language switching**
5. **Create location management (can be mocked for demo)**

### Functional Parity Summary:
- **Overall**: 15% (Major gaps in multi-site, permissions, and basic auth)
- **Critical for Demo**: Login and navigation fixes needed
- **Can be deferred**: Multi-site configuration, complex permissions