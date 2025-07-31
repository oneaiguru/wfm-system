# R2-EmployeeSelfService Complete 57 Scenarios Detailed Execution Plan

## 🎯 **COMPREHENSIVE SCENARIO MAPPING WITH MCP COMMANDS**

### **EMPLOYEE PORTAL AUTHENTICATION & SESSION MANAGEMENT (8 scenarios)**

#### **Scenario 1: Employee Portal Login**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/
mcp__playwright-human-behavior__screenshot → capture employee portal login form
mcp__playwright-human-behavior__type → input[type="text"] → "test"
mcp__playwright-human-behavior__type → input[type="password"] → "test"
mcp__playwright-human-behavior__click → button:has-text('Войти')
mcp__playwright-human-behavior__wait_and_observe → .main-content
mcp__playwright-human-behavior__get_content → verify login success
```
**Evidence**: Vue.js portal interface, auto-authentication behavior, user context display
**Framework**: Vue.js + Vuetify vs admin PrimeFaces
**Russian Terms**: "Личный кабинет", "Войти"

#### **Scenario 2: Employee Portal Session Persistence**
```bash
# After login from Scenario 1
mcp__playwright-human-behavior__wait_and_observe → body → 300000 (5 minutes)
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/calendar
mcp__playwright-human-behavior__get_content → check if still logged in
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/requests
```
**Evidence**: SPA session persistence, better than admin portal
**Architecture**: Vue.js client-side routing vs PrimeFaces page reloads

#### **Scenario 3: Employee Portal Navigation Menu**
```bash
mcp__playwright-human-behavior__get_content → humanReading: true
# Capture all menu items
mcp__playwright-human-behavior__execute_javascript → 
`Array.from(document.querySelectorAll('.v-navigation-drawer a')).map(a => a.textContent.trim())`
mcp__playwright-human-behavior__screenshot → navigation menu
```
**Evidence**: Календарь, Профиль, Оповещения, Заявки, Биржа, Ознакомления, Пожелания
**Russian Terms**: Complete menu structure with translations

#### **Scenario 4: Employee Portal Theme System**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const themeButtons = document.querySelectorAll('button');
themeButtons.forEach(btn => {
  if (btn.textContent.includes('Темная')) {
    btn.click();
    return 'Dark theme activated';
  }
});`
mcp__playwright-human-behavior__wait_and_observe → body → 2000
mcp__playwright-human-behavior__screenshot → dark theme interface
# Switch back to light
```
**Evidence**: Theme switching functionality, JavaScript-driven UI changes
**Feature**: Interactive theme toggle with visual confirmation

#### **Scenario 5: Employee Portal URL Parameter Handling**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/calendar?date=2025-07-28
mcp__playwright-human-behavior__get_content → verify date parameter handling
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/requests?tab=available
mcp__playwright-human-behavior__screenshot → parameter-driven navigation
```
**Evidence**: SPA routing with URL parameter support
**Architecture**: Client-side parameter parsing

#### **Scenario 6: Employee Portal 404 Handling**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/profile
mcp__playwright-human-behavior__get_content → capture 404 behavior
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/dashboard
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/wishes
```
**Evidence**: SPA graceful 404 handling vs traditional page errors
**Architecture**: Vue.js router 404 patterns

#### **Scenario 7: Employee Portal No Logout Mechanism**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/logout
mcp__playwright-human-behavior__get_content → verify 404 response
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/auth/logout
mcp__playwright-human-behavior__screenshot → logout unavailability
```
**Evidence**: No logout functionality implementation
**Architecture Discovery**: Session management design difference

#### **Scenario 8: Employee Portal Auto-Authentication Pattern**
```bash
# Clear session storage
mcp__playwright-human-behavior__manage_storage → clear → all
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/
mcp__playwright-human-behavior__get_content → check if auto-logged in
# If login form appears, test credentials
mcp__playwright-human-behavior__type → input[type="text"] → "test"
mcp__playwright-human-behavior__type → input[type="password"] → "test"
```
**Evidence**: Auto-authentication frequency (~90% of time)
**Behavior Pattern**: Session restoration mechanism

### **VACATION REQUEST MANAGEMENT (12 scenarios)**

#### **Scenario 9: Navigate to Calendar for Request Creation**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/calendar
mcp__playwright-human-behavior__wait_and_observe → .calendar-container
mcp__playwright-human-behavior__screenshot → calendar interface
mcp__playwright-human-behavior__get_content → capture month display (juillet 2025)
```
**Evidence**: Full month calendar view, date selection capabilities
**Russian Terms**: "Календарь", month names in Russian/French

#### **Scenario 10: Request Creation Dialog Access**
```bash
# From calendar page
mcp__playwright-human-behavior__click → button:has-text('Создать')
mcp__playwright-human-behavior__wait_and_observe → .request-dialog
mcp__playwright-human-behavior__screenshot → request creation form
```
**Evidence**: Calendar-driven request initiation
**Form Discovery**: Request dialog structure and fields

#### **Scenario 11: Request Form Field Analysis**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const formAnalysis = {
  inputs: Array.from(document.querySelectorAll('input, textarea, select')).map(el => ({
    id: el.id, type: el.type, required: el.required, value: el.value
  })),
  validation: Array.from(document.querySelectorAll('.error--text, .v-messages__message')).map(el => el.textContent.trim())
};
return formAnalysis;`
```
**Evidence**: Complete form field inventory with IDs and requirements
**Known Fields**: #input-181 (date), #input-198 (comment), #input-245 (reason)

#### **Scenario 12: Request Type Selection Testing**
```bash
mcp__playwright-human-behavior__click → select[name="requestType"], .v-select
mcp__playwright-human-behavior__wait_and_observe → .v-menu
mcp__playwright-human-behavior__screenshot → request type dropdown
mcp__playwright-human-behavior__click → *:has-text('Заявка на создание отгула')
```
**Evidence**: Request type options available
**Russian Terms**: "Заявка на создание отгула", "Заявка на создание больничного"

#### **Scenario 13: Date Field Dual Input Testing**
```bash
# Test text input date field
mcp__playwright-human-behavior__type → #input-181 → "2025-08-15"
# Test calendar picker selection
mcp__playwright-human-behavior__click → .calendar-day:has-text('15')
# Verify synchronization
mcp__playwright-human-behavior__execute_javascript → 
`document.querySelector('#input-181').value`
```
**Evidence**: Dual date requirement pattern - text input AND calendar selection
**Blocker Discovery**: Calendar-date desynchronization issues

#### **Scenario 14: Request Form Field Validation**
```bash
# Submit incomplete form to trigger validation
mcp__playwright-human-behavior__click → button:has-text('Добавить')
mcp__playwright-human-behavior__get_content → capture validation messages
mcp__playwright-human-behavior__screenshot → validation errors
```
**Evidence**: Russian validation messages with specific requirements
**Validation Patterns**: "Поле должно быть заполнено", "Заполните дату в календаре"

#### **Scenario 15: Complete Request Form Submission**
```bash
# Fill all known required fields
mcp__playwright-human-behavior__click → select → option:has-text('Заявка на создание отгула')
mcp__playwright-human-behavior__type → #input-181 → "2025-08-15"
mcp__playwright-human-behavior__click → .calendar-day:has-text('15')
mcp__playwright-human-behavior__type → #input-245 → "Личные обстоятельства"
mcp__playwright-human-behavior__type → #input-198 → "Тестовая заявка на отпуск"
mcp__playwright-human-behavior__click → button:has-text('Добавить')
mcp__playwright-human-behavior__wait_and_observe → .response-message
```
**Evidence**: Complete form submission attempt
**CRITICAL BLOCKER**: Validation persists despite all visible fields completed

#### **Scenario 16: Request Form Date Format Testing**
```bash
# Test different date formats
mcp__playwright-human-behavior__type → #input-181 → "15.08.2025" # DD.MM.YYYY Russian
mcp__playwright-human-behavior__click → button:has-text('Добавить')
mcp__playwright-human-behavior__get_content → capture result
# Test alternative format
mcp__playwright-human-behavior__type → #input-181 → "15/08/2025" # DD/MM/YYYY
```
**Evidence**: Date format requirements testing
**Investigation**: Russian locale date format preferences

#### **Scenario 17: Request Form Hidden Field Discovery**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const hiddenInputs = Array.from(document.querySelectorAll('input[type="hidden"]')).map(el => ({
  id: el.id, value: el.value, name: el.name
}));
const allRequiredFields = Array.from(document.querySelectorAll('[required]')).filter(el => !el.value);
return { hiddenInputs, allRequiredFields };`
```
**Evidence**: Investigation of invisible form requirements
**Debug Purpose**: Identify missing validation triggers

#### **Scenario 18: Request Navigation to "Мои" Tab**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/requests
mcp__playwright-human-behavior__wait_and_observe → .v-tabs
mcp__playwright-human-behavior__screenshot → requests interface
mcp__playwright-human-behavior__get_content → capture tab structure
```
**Evidence**: Two-tab request interface design
**Tab Structure**: "Мои" (my requests), "Доступные" (available requests)

#### **Scenario 19: Request Navigation to "Доступные" Tab**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const targetTab = Array.from(document.querySelectorAll('*[role="tab"], .v-tab')).find(tab => 
  tab.textContent.includes('Доступные')
);
if (targetTab) {
  targetTab.click();
  return 'Clicked tab: ' + targetTab.textContent;
}`
mcp__playwright-human-behavior__wait_and_observe → .tab-content
```
**Evidence**: Tab navigation patterns in Vue.js SPA
**URL Routing**: Fragment-based tab routing

#### **Scenario 20: Request Table Structure Analysis**
```bash
mcp__playwright-human-behavior__get_content → includeHTML: false
mcp__playwright-human-behavior__execute_javascript → 
`const tableHeaders = Array.from(document.querySelectorAll('th')).map(th => th.textContent.trim());
const requestCount = document.querySelectorAll('tr[data-request]').length;
return { tableHeaders, requestCount };`
```
**Evidence**: Request data structure and display patterns
**Table Headers**: "Дата создания", "Тип заявки", "Желаемая дата", "Статус"

### **NOTIFICATION SYSTEM (8 scenarios)**

#### **Scenario 21: Navigate to Notifications**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/notifications
mcp__playwright-human-behavior__wait_and_observe → .notifications-container
mcp__playwright-human-behavior__screenshot → notifications interface
mcp__playwright-human-behavior__get_content → count total notifications
```
**Evidence**: 106+ operational notifications with real timestamps
**Live Data**: Real operational system, not demo data

#### **Scenario 22: Notification Content Analysis**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const notifications = Array.from(document.querySelectorAll('.notification-item')).slice(0, 5).map(item => ({
  title: item.querySelector('.title')?.textContent,
  timestamp: item.querySelector('.timestamp')?.textContent,
  status: item.querySelector('.status')?.textContent
}));
return notifications;`
```
**Evidence**: Live operational data with real timestamps (+05:00 timezone)
**Content Types**: Daily notifications, acknowledgment requests

#### **Scenario 23: Notification Filtering**
```bash
mcp__playwright-human-behavior__click → .filter-button
mcp__playwright-human-behavior__wait_and_observe → .filter-menu
mcp__playwright-human-behavior__click → input[type="checkbox"]:first
mcp__playwright-human-behavior__wait_and_observe → .filtered-results
mcp__playwright-human-behavior__screenshot → filtered notifications
```
**Evidence**: Notification filtering capabilities
**Filter Options**: Status, type, date range filters

#### **Scenario 24: Notification Interaction Testing**
```bash
mcp__playwright-human-behavior__click → .notification-item:first
mcp__playwright-human-behavior__wait_and_observe → .notification-detail
mcp__playwright-human-behavior__get_content → capture interaction result
```
**Evidence**: Notification clickability and detail display
**Interaction Pattern**: Expandable notification details

#### **Scenario 25: Navigate to Acknowledgments**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/introduce
mcp__playwright-human-behavior__wait_and_observe → .acknowledgments-container
mcp__playwright-human-behavior__screenshot → acknowledgments interface
```
**Evidence**: Daily acknowledgment system
**Live Users**: "Бирюков Юрий Артёмович" acknowledgments

#### **Scenario 26: Acknowledgment Processing**
```bash
mcp__playwright-human-behavior__click → button:has-text("Ознакомлен(а)")
mcp__playwright-human-behavior__wait_and_observe → .status-change
mcp__playwright-human-behavior__get_content → capture status change
```
**Evidence**: LIVE DATA CHANGES - Status "Новый" → "Ознакомлен(а)" + timestamp
**System Proof**: Real operational system with state changes

#### **Scenario 27: Acknowledgment Status Verification**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const statusItems = Array.from(document.querySelectorAll('.status-item')).map(item => ({
  user: item.querySelector('.user-name')?.textContent,
  status: item.querySelector('.status')?.textContent,
  timestamp: item.querySelector('.timestamp')?.textContent
}));
return statusItems;`
```
**Evidence**: User-specific acknowledgment tracking
**Status Transitions**: "Новый" → "Ознакомлен(а)" with timestamps

#### **Scenario 28: Notification Response Testing**
```bash
# Look for notifications requiring response
mcp__playwright-human-behavior__get_content → includeHTML: false
# Check for "Просьба сообщить о своей готовности" type notifications
mcp__playwright-human-behavior__click → .notification-item:has-text('готовности')
mcp__playwright-human-behavior__wait_and_observe → .response-options
```
**Evidence**: Response-required notification patterns
**Interactive Elements**: Notification action buttons

### **EXCHANGE SYSTEM (6 scenarios)**

#### **Scenario 29: Navigate to Exchange**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/exchange  
mcp__playwright-human-behavior__wait_and_observe → .exchange-container
mcp__playwright-human-behavior__screenshot → exchange interface
mcp__playwright-human-behavior__get_content → capture exchange structure
```
**Evidence**: Two-tab exchange system structure
**URL Routing**: Fragment routing for tab navigation

#### **Scenario 30: Exchange "Мои" Tab Analysis**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const myTab = Array.from(document.querySelectorAll('.v-tab')).find(tab => 
  tab.textContent.includes('Мои')
);
if (myTab) myTab.click();`
mcp__playwright-human-behavior__wait_and_observe → .my-exchanges
mcp__playwright-human-behavior__get_content → capture my exchanges content
```
**Evidence**: User's exchange requests display
**Current State**: Empty or limited data for test user

#### **Scenario 31: Exchange "Доступные" Tab Analysis** 
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const availableTab = Array.from(document.querySelectorAll('.v-tab')).find(tab => 
  tab.textContent.includes('Доступные')
);
if (availableTab) availableTab.click();`
mcp__playwright-human-behavior__wait_and_observe → .available-exchanges
```
**Evidence**: Available exchange opportunities display
**Fragment Routing**: #tabs-available-offers URL pattern

#### **Scenario 32: Exchange Creation Investigation**
```bash
mcp__playwright-human-behavior__click → button:contains('Создать'), button:contains('Добавить')
mcp__playwright-human-behavior__wait_and_observe → .creation-dialog
mcp__playwright-human-behavior__screenshot → exchange creation interface
```
**Evidence**: Exchange creation availability testing
**Expected Blocker**: No visible creation interface for test user

#### **Scenario 33: Exchange Participation Testing**
```bash
# If exchanges visible in "Доступные" tab
mcp__playwright-human-behavior__click → .exchange-item:first .participate-button
mcp__playwright-human-behavior__wait_and_observe → .participation-dialog
mcp__playwright-human-behavior__screenshot → participation interface
```
**Evidence**: Exchange participation workflow
**Role Dependency**: May require different user permissions

#### **Scenario 34: Exchange Status Tracking**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const exchanges = Array.from(document.querySelectorAll('.exchange-item')).map(item => ({
  title: item.querySelector('.title')?.textContent,
  status: item.querySelector('.status')?.textContent,
  date: item.querySelector('.date')?.textContent
}));
return exchanges;`
```
**Evidence**: Exchange status management system
**Status Types**: Various exchange states and transitions

### **PROFILE & PERSONAL SETTINGS (6 scenarios)**

#### **Scenario 35: Profile Access Testing**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/profile
mcp__playwright-human-behavior__get_content → capture 404 response
mcp__playwright-human-behavior__screenshot → profile unavailability
```
**Evidence**: Profile feature not implemented (404 response)
**Architecture Gap**: Feature missing from employee portal

#### **Scenario 36: Profile Alternative Discovery**
```bash
# Search within functional pages for profile elements
mcp__playwright-human-behavior__execute_javascript → 
`const profileSearch = {
  userInfoElements: Array.from(document.querySelectorAll('*')).filter(el => 
    el.textContent && (el.textContent.includes('Профиль') || 
    el.textContent.includes('профил') || el.textContent.includes('настройки'))
  ),
  userDataDisplay: Array.from(document.querySelectorAll('*')).filter(el =>
    el.textContent && (el.textContent.includes('@') || 
    el.textContent.match(/\\d{4}-\\d{2}-\\d{2}/) || el.textContent.includes('тел'))
  )
};
return profileSearch;`
```
**Evidence**: Profile elements integrated within other pages
**Investigation**: User context display within calendar, requests, notifications

#### **Scenario 37: User Information Display**
```bash
# Check each functional page for user information
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/calendar
mcp__playwright-human-behavior__execute_javascript → 
`Array.from(document.querySelectorAll('*')).filter(el => 
  el.textContent && el.textContent.includes('test')
).map(el => el.textContent.trim())`
```
**Evidence**: User context display across different pages
**User Identification**: How "test" user is represented in interface

#### **Scenario 38: Personal Settings Discovery**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const settingsElements = Array.from(document.querySelectorAll('*')).filter(el =>
  el.textContent && (el.textContent.includes('настройки') || 
  el.textContent.includes('параметры') || el.textContent.includes('конфигурация'))
);
return settingsElements.map(el => el.textContent.trim());`
```
**Evidence**: Personal settings integration patterns
**Settings Location**: Embedded vs standalone settings

#### **Scenario 39: Theme Preferences Management**
```bash
# Test theme system preferences
mcp__playwright-human-behavior__execute_javascript → 
`const themeControls = Array.from(document.querySelectorAll('button, .theme-selector')).filter(el =>
  el.textContent && (el.textContent.includes('тем') || el.textContent.includes('Светл') || el.textContent.includes('Темн'))
);
return themeControls.map(el => el.textContent.trim());`
```
**Evidence**: Theme preference system
**Persistence Testing**: Theme selection maintenance across sessions

#### **Scenario 40: Language Settings Discovery**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const langElements = Array.from(document.querySelectorAll('*')).filter(el =>
  el.textContent && (el.textContent.includes('язык') || el.textContent.includes('language') || 
  el.textContent.includes('lang'))
);
return langElements.map(el => el.textContent.trim());`
```
**Evidence**: Language preference capabilities
**Default Language**: Russian interface with French month names pattern

### **CALENDAR & SCHEDULE MANAGEMENT (8 scenarios)**

#### **Scenario 41: Calendar Monthly View**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/calendar
mcp__playwright-human-behavior__wait_and_observe → .calendar-grid
mcp__playwright-human-behavior__screenshot → full month calendar
mcp__playwright-human-behavior__get_content → capture month display (juillet 2025)
```
**Evidence**: Complete monthly calendar view with date selection
**Month Display**: Mixed Russian/French nomenclature patterns

#### **Scenario 42: Calendar Date Selection**
```bash
mcp__playwright-human-behavior__click → .calendar-day:has-text('15')
mcp__playwright-human-behavior__wait_and_observe → .date-selected
mcp__playwright-human-behavior__screenshot → selected date highlighting
```
**Evidence**: Interactive date selection capabilities
**Visual Feedback**: Date selection highlighting and confirmation

#### **Scenario 43: Calendar Navigation Controls**
```bash
mcp__playwright-human-behavior__click → .calendar-nav-previous
mcp__playwright-human-behavior__wait_and_observe → .calendar-grid
mcp__playwright-human-behavior__screenshot → previous month
mcp__playwright-human-behavior__click → .calendar-nav-next
```
**Evidence**: Month navigation functionality
**Navigation Pattern**: Previous/next month controls

#### **Scenario 44: Calendar Event Display**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const events = Array.from(document.querySelectorAll('.calendar-event, .event-marker')).map(event => ({
  date: event.getAttribute('data-date'),
  type: event.className,
  content: event.textContent.trim()
}));
return events;`
```
**Evidence**: Calendar event/schedule display capabilities
**Event Types**: Different event markers and categories

#### **Scenario 45: Personal Schedule View**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const scheduleData = Array.from(document.querySelectorAll('.schedule-item, .shift-display')).map(item => ({
  time: item.querySelector('.time')?.textContent,
  description: item.querySelector('.description')?.textContent,
  status: item.querySelector('.status')?.textContent
}));
return scheduleData;`
```
**Evidence**: Personal schedule integration with calendar
**Schedule Elements**: Shift information, time slots, status indicators

#### **Scenario 46: Calendar Integration with Requests**
```bash
# Test if calendar shows pending/approved requests
mcp__playwright-human-behavior__execute_javascript → 
`const requestMarkers = Array.from(document.querySelectorAll('.request-marker, .vacation-marker')).map(marker => ({
  date: marker.getAttribute('data-date'),
  type: marker.getAttribute('data-type'),
  status: marker.getAttribute('data-status')
}));
return requestMarkers;`
```
**Evidence**: Request status integration with calendar display
**Visual Integration**: How requests appear on calendar

#### **Scenario 47: Calendar Responsive Design**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const mobileElements = document.querySelectorAll('[class*="mobile"], [class*="responsive"]').length;
const mediaQueries = (() => {
  let count = 0;
  try {
    for (let sheet of document.styleSheets) {
      try {
        for (let rule of sheet.cssRules || sheet.rules) {
          if (rule.type === CSSRule.MEDIA_RULE) count++;
        }
      } catch(e) {}
    }
  } catch(e) {}
  return count;
})();
return { mobileElements, mediaQueries };`
```
**Evidence**: Mobile responsiveness of calendar interface
**Mobile Architecture**: Vue.js native mobile support vs PrimeFaces retrofitted

#### **Scenario 48: Calendar URL Parameter Integration**
```bash
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/calendar?date=2025-07-28
mcp__playwright-human-behavior__wait_and_observe → .calendar-grid
mcp__playwright-human-behavior__execute_javascript → 
`document.querySelector('.selected-date, .current-date')?.textContent`
```
**Evidence**: URL parameter handling for date navigation
**SPA Routing**: Parameter-driven calendar navigation

### **ERROR HANDLING & EDGE CASES (9 scenarios)**

#### **Scenario 49: Network Interruption Testing**
```bash
# Simulate connection issues during form submission
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/calendar
mcp__playwright-human-behavior__click → button:has-text('Создать')
# Fill form and test submission during simulated network issues
mcp__playwright-human-behavior__type → #input-181 → "2025-08-15"
# Wait for potential timeout
mcp__playwright-human-behavior__wait_and_observe → .error-message → 30000
```
**Evidence**: Network error handling and recovery patterns
**SPA Resilience**: Vue.js error handling vs PrimeFaces

#### **Scenario 50: Invalid Data Handling**
```bash
mcp__playwright-human-behavior__type → #input-181 → "invalid-date"
mcp__playwright-human-behavior__type → #input-198 → "<script>alert('test')</script>"
mcp__playwright-human-behavior__click → button:has-text('Добавить')
mcp__playwright-human-behavior__get_content → capture validation response
```
**Evidence**: Input sanitization and validation patterns
**Security Testing**: XSS prevention, data validation

#### **Scenario 51: Session Recovery Testing**
```bash
# Clear session storage mid-workflow
mcp__playwright-human-behavior__manage_storage → clear → sessionStorage
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/requests
mcp__playwright-human-behavior__get_content → capture recovery behavior
```
**Evidence**: Session recovery and auto-authentication patterns
**SPA Behavior**: Client-side session management

#### **Scenario 52: Form Validation Edge Cases**
```bash
# Test boundary conditions
mcp__playwright-human-behavior__type → #input-181 → "2025-02-30" # Invalid date
mcp__playwright-human-behavior__type → #input-198 → "a".repeat(1000) # Long text
mcp__playwright-human-behavior__click → button:has-text('Добавить')
```
**Evidence**: Edge case validation handling
**Validation Rules**: Length limits, date validation, format requirements

#### **Scenario 53: Concurrent User Testing**
```bash
# Test behavior with multiple browser contexts
mcp__playwright-human-behavior__manage_storage → set → sessionStorage → test_user_1
# Simulate second user session interactions
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/exchange
```
**Evidence**: Multi-user session handling
**Conflict Resolution**: Concurrent access patterns

#### **Scenario 54: JavaScript Error Recovery**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`// Intentionally trigger JS error to test recovery
throw new Error('Test error for recovery testing');`
mcp__playwright-human-behavior__wait_and_observe → body → 5000
mcp__playwright-human-behavior__get_content → verify interface stability
```
**Evidence**: JavaScript error handling and recovery
**Vue.js Resilience**: Error boundary patterns

#### **Scenario 55: Mobile Viewport Testing**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`document.querySelector('meta[name="viewport"]')?.content`
mcp__playwright-human-behavior__screenshot → fullPage: true
# Test mobile navigation patterns
```
**Evidence**: Mobile viewport optimization
**Mobile Strategy**: Vue.js native mobile vs PrimeFaces mobile

#### **Scenario 56: Accessibility Testing**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const a11yElements = {
  ariaLabels: document.querySelectorAll('[aria-label]').length,
  roles: document.querySelectorAll('[role]').length,
  altTexts: document.querySelectorAll('img[alt]').length,
  focusable: document.querySelectorAll('[tabindex]').length
};
return a11yElements;`
```
**Evidence**: Accessibility implementation patterns
**A11Y Support**: ARIA labels, keyboard navigation, screen reader support

#### **Scenario 57: Performance & Load Testing**
```bash
mcp__playwright-human-behavior__execute_javascript → 
`const performanceData = {
  loadTime: performance.timing.loadEventEnd - performance.timing.navigationStart,
  domReady: performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart,
  resources: performance.getEntriesByType('resource').length
};
return performanceData;`
```
**Evidence**: Employee portal performance characteristics
**Performance Comparison**: Vue.js SPA vs PrimeFaces page loads

---

## 🔧 **SYSTEMATIC RECOVERY APPROACH FOR BLOCKED SCENARIOS**

### **For Request Form Validation Issues (8-10 scenarios affected):**
1. **Alternative user testing**: Try Konstantin/12345 credentials
2. **Date format variations**: DD.MM.YYYY, DD/MM/YYYY, YYYY-MM-DD
3. **Hidden field discovery**: JavaScript form analysis
4. **Network monitoring**: Capture actual API calls during submission
5. **Backend comparison**: Test admin portal request creation for employees

### **For Missing Features (Profile, Exchange Creation):**
1. **Role-based testing**: Try different user credentials
2. **Admin portal comparison**: Check if features exist on admin side
3. **Alternative access paths**: Look for integrated functionality
4. **Permission documentation**: Map feature access by user type

### **For SPA Navigation Issues:**
1. **Fragment routing**: Test #hash-based navigation
2. **Parameter handling**: URL parameter support testing
3. **State management**: Vue.js client-side state persistence
4. **Error boundaries**: 404 handling in SPA vs traditional pages

## 📊 **REALISTIC COMPLETION TRACKING**

**Currently Verified with Full MCP**: 34/57 scenarios (59.6%)
**Critical Blocker Resolution**: Request form validation - unlocks 8+ scenarios
**Can Complete with User Testing**: +15-20 scenarios (alternative credentials)
**Architecture Dependent**: 5-8 scenarios (may not exist for employee users)
**Edge Cases & Advanced**: 5-8 scenarios (lower priority)

**Realistic Target**: 48-52/57 scenarios (84-91%) with systematic debugging approach

**Completion Dependencies**:
1. **Request form resolution**: Unlocks entire vacation request workflow
2. **User permission comparison**: Reveals feature availability patterns
3. **Profile discovery**: Alternative profile management approaches
4. **Exchange system**: Role-based feature access testing

---

This detailed plan provides specific MCP commands for EVERY R2 employee portal scenario, with particular focus on the request form validation blocker that is the key to unlocking significant domain completion progress.