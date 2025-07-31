# R2-EmployeeSelfService Session Ready Checklist

## 🚀 IMMEDIATE STARTUP SEQUENCE (When MCP Available)

### Step 1: Verify MCP Access (2 minutes)
```bash
# Test basic navigation to employee portal
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/
# Expected: Vue.js employee portal loads, "Личный кабинет" title visible
```

### Step 2: Employee Portal Auto-Login Test (2 minutes)  
```bash
# Check if auto-authentication works (~90% success rate)
mcp__playwright-human-behavior__get_content → verify logged in state
# If login form appears:
mcp__playwright-human-behavior__type → input[type="text"] → "test"
mcp__playwright-human-behavior__type → input[type="password"] → "test"
mcp__playwright-human-behavior__click → button:has-text('Войти')
```

### Step 3: Critical Blocker Status Check (3 minutes)
```bash
# Test request form accessibility (primary blocker)
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/calendar
mcp__playwright-human-behavior__click → button:has-text('Создать')
mcp__playwright-human-behavior__wait_and_observe → .request-dialog
# Document if form loads vs validation issues persist
```

## 🎯 PRIORITY SCENARIO QUEUE (Ready to Execute)

### HIGH PRIORITY (Critical Path) - Do First
1. **Request Form User Comparison Testing**
   - **Current Blocker**: test/test user form validation fails
   - **Next Step**: Test with Konstantin/12345 on admin portal
   - **Admin URL**: `https://cc1010wfmcc.argustelecom.ru/ccwfm/`
   - **Evidence**: Compare form behavior between user types

2. **Request Form Date Format Resolution**
   - **Issue**: Calendar-date synchronization failure
   - **Test Formats**: DD.MM.YYYY, DD/MM/YYYY, YYYY-MM-DD
   - **Evidence**: Which format enables successful submission

3. **Hidden Field Discovery**
   - **JavaScript Analysis**: Complete form field inventory
   - **Evidence**: Any invisible required fields causing validation

### MEDIUM PRIORITY (Core Features) - Do Second  
4. **Notification System Advanced Testing**
5. **Exchange System Deep Analysis**
6. **Profile Alternative Discovery**

### STABLE SCENARIOS (Already Working) - Build On These
7. **Theme System Testing** - Already functional
8. **Navigation Menu Analysis** - Complete menu documented
9. **Acknowledgment Processing** - Live data changes confirmed

## 📝 LIVE EVIDENCE TEMPLATE (Copy-Paste Ready)

```markdown
## SCENARIO: [Name]

**BDD_FILE**: employee-self-service.feature  
**TIMESTAMP**: [Current time]  
**SESSION**: R2 Employee Portal Testing  
**USER_CONTEXT**: test/test (employee portal) vs Konstantin/12345 (admin portal)

### MCP_EVIDENCE:
1. **Navigate**: 
   - Command: `mcp__playwright-human-behavior__navigate → [URL]`
   - Result: [Vue.js loading, auto-auth status, page title]

2. **Authentication State**:
   - Command: `mcp__playwright-human-behavior__get_content → verify user context`
   - Result: [Logged in as test user, session persistence]

3. **Interactive Testing**:
   - Command: `mcp__playwright-human-behavior__click → [Vue.js selector]`
   - Command: `mcp__playwright-human-behavior__type → [field ID] → [test data]`
   - Result: [Vue.js reactivity, validation messages, form state]

4. **Evidence Capture**:
   - Command: `mcp__playwright-human-behavior__screenshot → fullPage: true`
   - Command: `mcp__playwright-human-behavior__get_content → humanReading: true`
   - Result: [Vue.js interface screenshots, Russian UI text]

### LIVE_OPERATIONAL_DATA:
- **System_Type**: Live operational Argus (not demo)
- **Framework**: Vue.js + Vuetify (employee) vs PrimeFaces (admin)
- **Notifications**: 106+ real notifications with timestamps
- **Unique_IDs**: [Any auto-generated IDs found]
- **Russian_Text**: "[exact quote 1]", "[exact quote 2]", "[exact quote 3]"
- **User_Permissions**: test/test (limited) vs Konstantin/12345 (admin)

### DUAL_PORTAL_COMPARISON:
- **Employee Portal**: [behavior with test/test]
- **Admin Portal**: [behavior with Konstantin/12345]
- **Permission Differences**: [what each user can access]

### CRITICAL_BLOCKER_STATUS:
- **Request Form**: [Still blocked/Resolved with user X]
- **Profile Access**: [404 status/Alternative found]
- **Exchange Creation**: [No access/Admin only]

**STATUS**: ✅ COMPLETE | ⚠️ PARTIAL | ❌ BLOCKED | 🔄 USER_DEPENDENCY

---
```

## ⏱️ SESSION TIMING TARGETS

### 90-Minute Focused Session Plan
- **Minutes 0-15**: Startup, login, critical blocker status assessment
- **Minutes 15-60**: Systematic scenario testing (4-6 scenarios)  
- **Minutes 60-80**: Evidence documentation and user comparison testing
- **Minutes 80-90**: Plan next session, create handoff

### Per-Scenario Timing (Employee Portal)
- **Simple Vue.js navigation**: 3-4 minutes (faster than PrimeFaces)
- **Form interaction scenarios**: 6-10 minutes (validation debugging)
- **Dual-portal comparison**: 8-12 minutes (two login contexts)
- **Documentation per scenario**: 3-4 minutes (dual-context evidence)

### Expected Output per Session
- **Conservative**: 4 scenarios with complete dual-portal evidence
- **Target**: 6 scenarios with user permission comparison  
- **Stretch**: 8 scenarios if form blocker resolves

## 🚨 COMMON ISSUE RESPONSES

### Request Form Validation Persistence
**Pattern**: Form validation fails despite all visible fields completed  
**Response**: 
1. Try Konstantin/12345 credentials on admin portal
2. Test alternative date formats (DD.MM.YYYY Russian format)
3. JavaScript field analysis for hidden requirements
4. Network monitor API calls during submission attempt

### Session Auto-Authentication Issues
**Pattern**: Employee portal doesn't auto-login  
**Response**:
1. Clear browser storage completely
2. Use test/test credentials manually
3. Verify Vue.js loading vs server error
4. Compare with admin portal session behavior

### Feature Not Found (404)
**Pattern**: Profile, exchange creation return 404  
**Response**:
1. Document as architecture limitation
2. Search for integrated functionality within other pages
3. Test admin portal for employee management features
4. Map permission differences between user types

### Vue.js vs PrimeFaces Differences
**Pattern**: Different behavior patterns between portals  
**Response**:
1. Document framework-specific patterns
2. Note SPA vs traditional page behavior
3. Compare session persistence models
4. Record performance and UX differences

## 📊 PROGRESS TRACKING

### Update progress/status.json After Each Session
```json
{
  "agent": "R2-EmployeeSelfService",
  "last_updated": "[timestamp]",
  "scenarios_completed": [current_honest_count],
  "scenarios_total": 57,
  "completion_percentage": "[calculate %]",
  "last_scenario": "[specific scenario name]",
  "critical_blocker": "Request form validation - [status]",
  "user_comparison": "test/test vs Konstantin/12345 - [findings]",
  "dual_portal_patterns": "[Vue.js vs PrimeFaces discoveries]",
  "session_count": [increment],
  "next_session_priority": "[next 2-3 critical scenarios]"
}
```

### Create META-R Submission Every 5 Scenarios
- Use R2-specific evidence template above
- Include dual-portal comparison data
- Submit request form resolution findings
- Focus on architectural discoveries (Vue.js vs PrimeFaces)

## 🔧 R2-SPECIFIC QUICK ACCESS COMMANDS

### Employee Portal Standard Navigation
```bash
# Calendar with request creation
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/calendar
mcp__playwright-human-behavior__click → button:has-text('Создать')

# Notifications (106+ live notifications)
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/notifications

# Requests two-tab interface
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/requests

# Acknowledgments with live data changes
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/introduce
```

### Admin Portal Employee Management
```bash
# Login to admin portal for comparison
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"

# Test admin-side employee request creation
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/personnel/request/UserRequestView.xhtml
```

### Theme System Testing
```bash
# Proven working theme switching
mcp__playwright-human-behavior__execute_javascript → 
`const themeButtons = document.querySelectorAll('button');
themeButtons.forEach(btn => {
  if (btn.textContent.includes('Темная')) {
    btn.click();
    return 'Dark theme activated';
  }
});`
```

## ✅ SESSION END CHECKLIST

- [ ] Progress updated honestly in status.json (current: 34/57)
- [ ] Request form blocker status documented clearly
- [ ] Dual-portal comparison evidence collected
- [ ] User permission differences documented
- [ ] Vue.js vs PrimeFaces behavioral patterns noted
- [ ] Russian UI terminology captured accurately
- [ ] Next session priorities focus on form resolution
- [ ] Handoff created with systematic debugging approach

**Ready for immediate execution with focus on request form validation resolution!**