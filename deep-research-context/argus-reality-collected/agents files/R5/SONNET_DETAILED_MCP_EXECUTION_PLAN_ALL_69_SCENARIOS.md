# Sonnet Detailed MCP Execution Plan - ALL 69 Scenarios

**CRITICAL**: Execute EVERY tool call. Do NOT stop until all 69 scenarios are tested with MCP evidence.

## 🎯 Mission: Test ALL 69 Scenarios from Domain Package

### Setup Phase
```bash
# 1. Login to Admin Portal
mcp__playwright-human-behavior__navigate → "https://cc1010wfmcc.argustelecom.ru/ccwfm/"
mcp__playwright-human-behavior__type → "input[type='text']" → "Konstantin"
mcp__playwright-human-behavior__type → "input[type='password']" → "12345"
mcp__playwright-human-behavior__click → "button[type='submit']"
mcp__playwright-human-behavior__wait_and_observe → "body" → 3000
```

## Feature 1: 03-complete-business-process.feature (10 scenarios)

### SPEC-001: Successful Employee Portal Authentication
```bash
# Navigate to employee portal
mcp__playwright-human-behavior__navigate → "https://lkcc1010wfmcc.argustelecom.ru/"
mcp__playwright-human-behavior__screenshot → fullPage: true
mcp__playwright-human-behavior__type → "input[type='text']" → "test"
mcp__playwright-human-behavior__type → "input[type='password']" → "test"
mcp__playwright-human-behavior__click → "button:has-text('Войти')"
mcp__playwright-human-behavior__wait_and_observe → ".v-list-item" → 3000
# Document: Login form, Russian text, success state
```

### SPEC-002: Employee Portal Navigation Access
```bash
# Check all navigation items
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('nav a, .v-list-item')).map(el => ({text: el.textContent, href: el.href}))"
mcp__playwright-human-behavior__screenshot → selector: "nav"
# Test each navigation link
mcp__playwright-human-behavior__click → "a[href*='calendar']"
mcp__playwright-human-behavior__wait_and_observe → body → 2000
mcp__playwright-human-behavior__click → "a[href*='requests']"
mcp__playwright-human-behavior__wait_and_observe → body → 2000
```

### SPEC-003: Create Request via Calendar Interface
```bash
# Navigate to calendar
mcp__playwright-human-behavior__navigate → "https://lkcc1010wfmcc.argustelecom.ru/calendar"
mcp__playwright-human-behavior__wait_and_observe → ".calendar" → 3000
# Click on date
mcp__playwright-human-behavior__click → ".calendar-day:not(.disabled):first"
# Look for request creation
mcp__playwright-human-behavior__execute_javascript → "document.querySelector('[class*=request], [class*=заявк]')"
mcp__playwright-human-behavior__screenshot → fullPage: true
```

### SPEC-004: Verify Exchange Request in Exchange System
```bash
# Navigate to exchange
mcp__playwright-human-behavior__navigate → "https://lkcc1010wfmcc.argustelecom.ru/exchange"
mcp__playwright-human-behavior__wait_and_observe → body → 3000
mcp__playwright-human-behavior__screenshot → fullPage: true
# Look for tabs
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('[role=tab], .v-tab')).map(t => t.textContent)"
# Click each tab
mcp__playwright-human-behavior__click → "[role=tab]:nth-child(1)"
mcp__playwright-human-behavior__wait_and_observe → body → 2000
mcp__playwright-human-behavior__click → "[role=tab]:nth-child(2)"
```

### SPEC-005: Accept Available Shift Exchange Request
```bash
# In exchange system, look for available shifts
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('button, [class*=accept]')).map(b => b.textContent)"
# Click accept if found
mcp__playwright-human-behavior__click → "button:has-text('Принять'), button:has-text('Accept')"
mcp__playwright-human-behavior__screenshot → fullPage: true
```

### SPEC-006: Supervisor Approve Time Off/Sick Leave/Vacation Request
```bash
# Back to admin portal
mcp__playwright-human-behavior__navigate → "https://cc1010wfmcc.argustelecom.ru/ccwfm/"
# Navigate to requests
mcp__playwright-human-behavior__execute_javascript → "document.querySelector('a[href*=request], a:has-text(Заявки)').click()"
mcp__playwright-human-behavior__wait_and_observe → body → 3000
# Look for pending approvals
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('tr, .request-row')).slice(0,5).map(r => r.textContent)"
# Click approve button
mcp__playwright-human-behavior__click → "button:has-text('Одобрить'), button:has-text('Approve')"
```

### SPEC-007: Supervisor Approve Shift Exchange Request
```bash
# Look for exchange requests specifically
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('обмен') || el.textContent.includes('смен')).slice(0,5)"
mcp__playwright-human-behavior__click → "button:has-text('Одобрить')"
mcp__playwright-human-behavior__screenshot → fullPage: true
```

### SPEC-008: Request Status Progression Tracking
```bash
# Check status column
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('td')).filter(td => td.textContent.includes('Статус') || td.textContent.includes('статус')).map(td => td.nextElementSibling?.textContent)"
# Document status values found
mcp__playwright-human-behavior__screenshot → selector: "table"
```

### SPEC-009: Direct API Authentication Validation
```bash
# Check network for API calls
mcp__playwright-human-behavior__execute_javascript → `
const xhrLog = [];
const open = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function(method, url) {
  xhrLog.push({method, url, timestamp: Date.now()});
  open.apply(this, arguments);
};
// Trigger some action
document.querySelector('button, a')?.click();
setTimeout(() => xhrLog, 2000);
`
```

### SPEC-010: Vue.js SPA Framework Validation
```bash
# Check for Vue.js
mcp__playwright-human-behavior__execute_javascript → "typeof Vue !== 'undefined' || document.querySelector('#app').__vue__"
mcp__playwright-human-behavior__execute_javascript → "document.querySelector('script[src*=vue]')"
```

## Feature 2: 13-business-process-management-workflows.feature (15 scenarios)

### SPEC-001: Load Business Process Definitions
```bash
# Navigate to BPMS section
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('a, span')).find(el => el.textContent.includes('BPMS') || el.textContent.includes('бизнес-процесс'))?.click()"
mcp__playwright-human-behavior__wait_and_observe → body → 3000
mcp__playwright-human-behavior__screenshot → fullPage: true
# Document what loads
```

### SPEC-002: Work Schedule Approval Process Workflow
```bash
# Look for workflow definitions
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('график') || el.textContent.includes('расписан')).slice(0,10)"
# Click on schedule workflow
mcp__playwright-human-behavior__click → "a:has-text('График'), a:has-text('Расписание')"
```

### SPEC-003: Handle Approval Tasks in Workflow
```bash
# Look for task list
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('задач') || el.textContent.includes('task')).slice(0,10)"
mcp__playwright-human-behavior__screenshot → fullPage: true
```

### SPEC-004: Process Notification Management
```bash
# Check notification settings
mcp__playwright-human-behavior__execute_javascript → "document.querySelector('[class*=notification], [class*=уведомлен]')"
mcp__playwright-human-behavior__click → "a:has-text('Уведомления'), a:has-text('Notifications')"
```

### SPEC-005: Employee Vacation Request Approval Workflow
```bash
# Look for vacation workflow
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('отпуск') || el.textContent.includes('vacation')).slice(0,10)"
mcp__playwright-human-behavior__screenshot → fullPage: true
```

### SPEC-006: Shift Exchange Approval Workflow
```bash
# Look for exchange workflow
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('обмен смен') || el.textContent.includes('exchange')).slice(0,10)"
```

### SPEC-007: Handle Workflow Escalations and Timeouts
```bash
# Look for escalation settings
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('эскалац') || el.textContent.includes('timeout')).slice(0,10)"
```

### SPEC-008: Delegate Tasks and Manage Substitutions
```bash
# Look for delegation
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('делегир') || el.textContent.includes('замещ')).slice(0,10)"
```

### SPEC-009: Handle Parallel Approval Workflows
```bash
# Look for parallel workflows
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('параллельн') || el.textContent.includes('parallel')).slice(0,10)"
```

### SPEC-010: Monitor Business Process Performance
```bash
# Look for performance metrics
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('производительност') || el.textContent.includes('performance')).slice(0,10)"
```

### SPEC-011 through SPEC-015
```bash
# Continue pattern for remaining workflow scenarios
# Each needs specific navigation and evidence capture
```

## Feature 3: 16-personnel-management-organizational-structure.feature (19 scenarios)

### SPEC-001: Create New Employee Profile
```bash
# Navigate to personnel
mcp__playwright-human-behavior__click → "a:has-text('Персонал'), a:has-text('Сотрудники')"
mcp__playwright-human-behavior__wait_and_observe → body → 3000
# Look for create button
mcp__playwright-human-behavior__click → "button:has-text('Создать'), button:has-text('Добавить')"
mcp__playwright-human-behavior__screenshot → fullPage: true
```

### SPEC-002: Assign Employee to Functional Groups
```bash
# Look for groups assignment
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('*')).filter(el => el.textContent.includes('групп') && el.textContent.includes('назнач')).slice(0,10)"
mcp__playwright-human-behavior__click → "a:has-text('Группы')"
```

### [Continue for all 19 personnel scenarios...]

## Feature 4: 15-real-time-monitoring-operational-control.feature (20 scenarios)

### SPEC-001: View Real-time Operational Control Dashboards
```bash
# Navigate to monitoring
mcp__playwright-human-behavior__navigate → "https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/monitoring/"
mcp__playwright-human-behavior__wait_and_observe → body → 3000
mcp__playwright-human-behavior__screenshot → fullPage: true
# Document all dashboard elements
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('.dashboard-widget, [class*=metric]')).map(w => w.textContent)"
```

### [Continue for all 20 monitoring scenarios...]

## 📋 Evidence Collection for EACH Scenario

For EVERY scenario above, collect:
1. **Navigation proof**: URL actually loads
2. **UI elements**: What's visible on screen
3. **Russian text**: All labels and messages
4. **Functionality**: Can it be clicked/interacted with
5. **API calls**: Network requests made
6. **Errors**: Any 403, 404, or error messages

## 🚨 DO NOT STOP Rules

1. If MCP fails on one scenario, document error and continue
2. If navigation fails, try alternative paths
3. If element not found, search broader and document
4. Complete ALL 69 scenarios even if some fail
5. Provide evidence chain for EVERY scenario attempt

## 📊 Expected Output Format

For EACH scenario:
```
SCENARIO: [SPEC-XXX name]
MCP_SEQUENCE:
  - [tool] → [parameter] → [result]
  - [tool] → [parameter] → [result]
FOUND: [What actually exists]
MISSING: [What spec expects but doesn't exist]
RUSSIAN_TERMS: [All Russian UI text]
STATUS: ✅ Working | ⚠️ Partial | ❌ Blocked
```

## 🎯 Success Criteria

- ALL 69 scenarios have MCP evidence
- No theoretical testing
- No assumptions
- Real screenshots/data for each
- Honest documentation of failures
- Complete in ONE session

START NOW. Do not stop until all 69 are tested.