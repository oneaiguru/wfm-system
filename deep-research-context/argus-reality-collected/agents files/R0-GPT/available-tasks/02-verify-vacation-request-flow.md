# Task 02: Verify Vacation Request Flow

## BDD Spec Reference
- **File**: `/project/specs/working/02-employee-requests.feature`
- **Lines**: 12-24 (Create Request for Time Off/Sick Leave)
- **Lines**: 27-37 (Create Shift Exchange Request)
- **Priority**: CRITICAL (matches our working implementation)

## Related Integration Knowledge
- **Vacation Journey Analysis**: `/agents/BDD-SCENARIO-AGENT-2/VACATION_JOURNEY_COMPLETE.md`
- **Integration Patterns**: `/agents/BDD-SCENARIO-AGENT-2/INTEGRATION_PATTERNS_LIBRARY_UPDATED.md`
- **Our Implementation**: `/project/src/ui/src/components/RequestForm.tsx`

## Test Objective
Verify vacation request creation process in Argus employee portal and compare with our implementation.

## Systems to Test
1. **Argus Employee Portal**: https://lkcc1010wfmcc.argustelecom.ru/ (test/test)
2. **Our System**: http://localhost:3000/requests (john.doe/test)

## Detailed Steps

### Step 1: Argus Employee Portal Vacation Request
```javascript
// Navigate to employee portal
await mcp__playwright-human-behavior__navigate({
  url: "https://lkcc1010wfmcc.argustelecom.ru/",
  waitForLoad: true
});

// Login with employee credentials
await mcp__playwright-human-behavior__type({
  selector: 'input[type="text"], input[name="username"], input[name="login"]',
  text: "test",
  humanTyping: true,
  clearFirst: true
});

await mcp__playwright-human-behavior__type({
  selector: 'input[type="password"], input[name="password"]',
  text: "test",
  humanTyping: true,
  clearFirst: true
});

await mcp__playwright-human-behavior__click({
  selector: 'button[type="submit"]',
  humanBehavior: true
});

// Wait for dashboard
await mcp__playwright-human-behavior__wait_and_observe({
  selector: "body",
  timeout: 5000,
  observationTime: 2000
});

// Navigate to Calendar tab (per BDD spec line 13)
// Look for: Календарь, Calendar, or similar
await mcp__playwright-human-behavior__execute_javascript({
  code: `
    const links = Array.from(document.querySelectorAll('a, button')).filter(
      el => el.textContent.includes('Календарь') || el.textContent.includes('Calendar')
    );
    if (links.length > 0) {
      links[0].click();
      return 'Clicked Calendar tab';
    }
    return 'Calendar tab not found';
  `,
  humanTiming: true
});

// Document what you see:
// 1. Is there a "Create" button as spec says (line 14)?
// 2. What request types are available?
// 3. How does the form look?

// Take screenshot of calendar/request page
await mcp__playwright-human-behavior__screenshot({
  fullPage: true
});
// Save as: /agents/ARGUS_COMPARISON/screenshots/argus/employee-calendar.png

// Look for request creation:
// - Create button (Создать)
// - Request types: sick leave (больничный), time off (отгул), vacation (отпуск)
// - Form fields required
```

### Step 2: Our System Vacation Request
```javascript
// Close Argus browser
await mcp__playwright-human-behavior__close();

// Navigate to our system
await mcp__playwright-official__browser_navigate({
  url: "http://localhost:3000"
});

// Login
await mcp__playwright-official__browser_type({
  element: "Username",
  ref: "[name='username']",
  text: "john.doe"
});

await mcp__playwright-official__browser_type({
  element: "Password",
  ref: "[name='password']",
  text: "test"
});

await mcp__playwright-official__browser_click({
  element: "Login button",
  ref: "[type='submit']"
});

// Navigate to requests
await mcp__playwright-official__browser_click({
  element: "Time Off link",
  ref: "[data-testid='time-off-link']"
});

// Document our form structure
await mcp__playwright-official__browser_snapshot();

// Take screenshot
await mcp__playwright-official__browser_take_screenshot({
  filename: "our-vacation-request-form.png"
});
```

### Step 3: Create Detailed Comparison

Create file: `/agents/ARGUS_COMPARISON/analysis/02-vacation-request-analysis.md`

```markdown
# Vacation Request Flow Analysis

## BDD Spec vs Reality

### Argus Employee Portal
**Navigation Flow**:
- [Document actual flow: Login → Calendar → Create]
- Available request types: [list what you found]
- Form fields: [list all fields]

**Key Differences from Spec**:
- Line 13: Spec says "Calendar tab" - Argus shows [actual]
- Line 14: Spec says "Create button" - Argus has [actual]
- Line 15: Request types in Argus: [list]

### Our Implementation
**Current State** (from VACATION_JOURNEY_COMPLETE.md):
- Route: /requests (not /requests/new)
- Form fields: startDate, endDate, type, reason
- Missing: name attributes on select/textarea

**Comparison**:
- Argus flow: [describe]
- Our flow: [describe]
- Key gaps: [list]

## Spec Updates Required

### Lines 12-24 (Create Request)
```gherkin
# UPDATED: Based on Argus actual behavior
Scenario: Create Request for Time Off/Sick Leave
  Given employee is logged into personal cabinet
  When employee navigates to [actual Argus navigation]
  And clicks [actual button name]
  And selects request type from [actual options]
  And fills in [actual required fields]
  And submits the request
  Then request appears with status [actual status]
```

### NEW: Missing Scenarios
```gherkin
# NEW: Request validation
Scenario: Validate overlapping requests
  Given employee has existing approved request
  When creating new request for same dates
  Then system shows conflict warning
```
```

## Success Criteria
- [ ] Argus vacation request flow fully documented
- [ ] Our implementation gaps identified
- [ ] BDD spec updates drafted
- [ ] Integration patterns applied

## Next Actions
1. Update RequestForm.tsx with missing attributes
2. Align navigation flow with Argus
3. Add validation scenarios to BDD spec