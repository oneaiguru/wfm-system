# BDD Scenarios and Documentation Collection for UI Implementation

Based on the BDD UI mapping, here are the collected scenarios and documentation organized by feature area with Demo Value 5 priorities.

## 1. System Architecture (Demo Value: 5)

### BDD Scenarios:
- **01-system-architecture.feature** - Scenario: Access Administrative System (lines 12-24)
  - Navigate to administrative system URL
  - Login with credentials
  - View dashboard with title and user greeting
  - See navigation options (Home, My Cabinet, Profile, About, Logout)

- **01-system-architecture.feature** - Scenario: Configure Multi-Site Location Management (lines 52-86)
  - Configure location hierarchy (Corporate/Regional/City/Site)
  - Set location properties (name, address, timezone, hours, capacity, status)
  - Implement location-specific business rules
  - Configure location synchronization
  - Set up location-specific reporting

### Related Documentation:
- **operator-cabinet-guide-en.md** - Personal Cabinet Login process (lines 29-37)
- **user-manual-mobile-en.md** - System login and authentication (lines 117-130)

## 2. Employee Self-Service (Demo Value: 5)

### BDD Scenarios:
- **02-employee-requests.feature** - Scenario: Create Request for Time Off/Sick Leave (lines 12-24)
  - Navigate to Calendar tab
  - Click Create button
  - Select request type (sick leave, time off, unscheduled vacation)
  - Fill in fields and submit
  - View request status on Requests page

- **02-employee-requests.feature** - Scenario: Create Shift Exchange Request (lines 27-37)
  - Navigate to Calendar tab
  - Select shift for exchange
  - Click three dots icon → Create request
  - Choose date/time for exchange
  - Submit and track status

- **14-mobile-personal-cabinet.feature** - Multiple scenarios for mobile access:
  - Mobile authentication (lines 12-24)
  - Personal cabinet login (lines 26-40)
  - Calendar schedule viewing (lines 43-58)
  - Request creation (lines 95-111)
  - Profile management (lines 165-182)

### Related Documentation:
- **operator-cabinet-guide-en.md** - Complete Personal Cabinet functionality:
  - Calendar page with schedule viewing (lines 65-92)
  - Request creation process (lines 114-129)
  - Requests management page (lines 133-153)
  - Profile page features (lines 157-171)
  - Notifications system (lines 175-185)

## 3. Scheduling & Planning (Demo Value: 5)

### BDD Scenarios:
- **10-monthly-intraday-activity-planning.feature** - Key scenarios:
  - Configure Event and Schedule Notifications (lines 13-26)
  - Create Detailed Daily Timetables (lines 81-99)
  - Handle Multi-skill Operator Planning (lines 100-115)
  - Make Manual Timetable Adjustments (lines 117-131)
  - Schedule Training and Development Events (lines 133-150)
  - Enhanced Working Days Calculation (lines 238-262)
  - Enhanced Planned Hours Calculation (lines 264-287)

### Related Documentation:
- **operator-cabinet-guide-en.md** - Calendar viewing modes:
  - Monthly/Weekly/4-day/Daily views (lines 69-75)
  - Shift details and intraday information (lines 79-86)
  - Preferences mode for schedule preferences (lines 93-112)

## 4. Mobile Applications (Demo Value: 5)

### BDD Scenarios:
- **14-mobile-personal-cabinet.feature** - Comprehensive mobile features:
  - Mobile Application Authentication (lines 12-24)
  - Personal Cabinet responsive interface (lines 26-40)
  - Mobile push notifications (lines 219-236)
  - Offline capability (lines 238-253)
  - Interface personalization (lines 255-271)
  - Dashboard customization (lines 273-292)

### Related Documentation:
- **user-manual-mobile-en.md** - Mobile User Manual overview
- **operator-cabinet-guide-en.md** - Responsive design mention (line 31)

## 5. Forecasting & Analytics (Demo Value: 5)

### BDD Scenarios:
- **30-special-events-forecasting.feature** - Unforecastable events configuration (lines 11-30)
  - Configure special event types (holidays, mass events, weather, technical, marketing)
  - Set event parameters (name, type, dates, load coefficient, service groups)

- **08-load-forecasting-demand-planning.feature** - Complete forecasting implementation:
  - Navigate to Forecast Load page (lines 17-25)
  - Historical data acquisition methods (lines 27-37)
  - Manual data import with Excel template (lines 39-55)
  - Growth factor application (lines 73-96)
  - Import forecasts functionality (lines 101-124)
  - Operator calculation with coefficients (lines 126-141)

### Related Documentation:
- **demand-forecasting-methods-en.md** - Complete forecasting documentation:
  - Three methods for demand planning (lines 15-22)
  - Load forecasting through Forecast Load page (lines 25-121)
  - Import forecasts for operator calculation (lines 123-188)
  - View Load page for operator plans (lines 190-281)
  - Historical data templates and formats
  - Aggregation logic and calculations

## Key UI Components to Implement (Priority Order):

1. **Login/Authentication System**
   - Multi-site support
   - Mobile-responsive design
   - Biometric authentication for mobile

2. **Dashboard & Navigation**
   - Role-based menu system
   - Quick access to main features
   - Notification center

3. **Calendar/Schedule View**
   - Multiple view modes (Monthly/Weekly/4-day/Daily)
   - Shift details with breaks/lunches
   - Preferences mode
   - Color customization

4. **Request Management**
   - Create requests (time off, sick leave, vacation, shift exchange)
   - Track request status
   - Available requests from others
   - Approval workflow

5. **Forecasting Interface**
   - Historical data import
   - Forecast parameters configuration
   - Growth factor application
   - Results visualization

6. **Mobile-Specific Features**
   - Push notifications
   - Offline mode
   - Touch-optimized interface
   - Calendar export

## Integration Points:

1. **1C ZUP Integration** - For time off and sick leave documents
2. **SSO Authentication** - Single sign-on support
3. **Production Calendar** - For holiday and working day calculations
4. **Notification Services** - Email, SMS, and push notifications
5. **Reporting Systems** - Data export and analytics

## Checklists Available:

While specific UI implementation checklists weren't found in the checklists directory, the following coverage reports and implementation guides are available:
- Coverage reports for various components
- Implementation guides for vacancy planning
- Parallel execution plans for development