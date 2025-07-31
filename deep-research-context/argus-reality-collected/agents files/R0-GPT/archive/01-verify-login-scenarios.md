# Task 01: Verify Login Scenarios

## BDD Spec Reference
- **File**: `/project/specs/working/01-system-architecture.feature`
- **Lines**: 12-24
- **Scenario**: "Access Administrative System"

## Test Objective
Compare login functionality between Argus WFM and our implementation to verify BDD spec accuracy.

## Systems to Test
1. **Argus Admin**: https://cc1010wfmcc.argustelecom.ru/ccwfm/ (Konstantin/12345)
2. **Our System**: http://localhost:3000 (admin/password)

## MCP Tool Usage
- **For Argus**: Use `mcp__playwright-human-behavior__` (handles anti-bot measures)
- **For Localhost**: Use `mcp__playwright-official__` (faster, no anti-bot needed)

## Detailed Steps

### Step 1: Test Argus Login
```javascript
// Navigate to Argus admin
await mcp__playwright-human-behavior__navigate({
  url: "https://cc1010wfmcc.argustelecom.ru/ccwfm/",
  waitForLoad: true
});

// Wait and observe page
await mcp__playwright-human-behavior__wait_and_observe({
  selector: "body",
  timeout: 5000,
  observationTime: 2000
});

// Document login form structure
// Look for: username field, password field, login button
// Note: Field names, IDs, classes, placeholder text

// Take screenshot
await mcp__playwright-human-behavior__screenshot({
  fullPage: false
});
// Save as: /agents/ARGUS_COMPARISON/screenshots/argus/login-form.png

// Try login (if no 403)
await mcp__playwright-human-behavior__type({
  selector: 'input[type="text"], input[name="username"], input[name="login"]',
  text: "Konstantin",
  humanTyping: true,
  clearFirst: true
});

await mcp__playwright-human-behavior__type({
  selector: 'input[type="password"], input[name="password"]',
  text: "12345",
  humanTyping: true,
  clearFirst: true
});

await mcp__playwright-human-behavior__click({
  selector: 'button[type="submit"], button:has-text("Войти")',
  humanBehavior: true
});

// Document post-login:
// - Dashboard elements
// - Navigation structure
// - User greeting format
```

### Step 2: Test Our System Login
```javascript
// Close Argus browser first
await mcp__playwright-human-behavior__close();

// Navigate to our system
await mcp__playwright-official__browser_navigate({
  url: "http://localhost:3000"
});

// Take snapshot
await mcp__playwright-official__browser_snapshot();

// Document login form
// Compare with Argus: field names, structure, flow

// Login
await mcp__playwright-official__browser_type({
  element: "Username input",
  ref: "[name='username']",
  text: "admin"
});

await mcp__playwright-official__browser_type({
  element: "Password input",
  ref: "[name='password']",
  text: "password"
});

await mcp__playwright-official__browser_click({
  element: "Login button",
  ref: "[type='submit']"
});

// Document post-login dashboard
```

### Step 3: Create Analysis
Create file: `/agents/ARGUS_COMPARISON/analysis/01-login-verification.md`

```markdown
# Login Scenario Verification

## BDD Spec Review
Lines 12-24 state:
- User navigates to system URL
- User enters username and password
- System validates credentials
- User sees dashboard with greeting

## Argus Actual Behavior
- Login form: [describe what you found]
- Field structure: [username/password field details]
- Post-login: [dashboard elements observed]
- Navigation: [menu structure]

## Our Implementation
- Login form: [compare with Argus]
- Field structure: [our implementation]
- Post-login: [our dashboard]
- Navigation: [our menu]

## Spec Updates Needed
- [ ] Line X: Update field names to match Argus
- [ ] Line Y: Add navigation structure details
- [ ] NEW: Add error handling scenario
```

## Expected Outcomes
1. Screenshots of both login screens
2. Detailed comparison of login flows
3. BDD spec update recommendations
4. Any missing scenarios identified

## Success Criteria
- Both systems tested successfully
- Login flow documented completely
- Spec gaps identified
- Analysis file created

## Files to Update
- `/project/specs/working/01-system-architecture.feature` (add verification comments)
- `/agents/ARGUS_COMPARISON/analysis/01-login-verification.md` (create)
- `/agents/ARGUS_COMPARISON/EXECUTIVE_SUMMARY.md` (update with findings)