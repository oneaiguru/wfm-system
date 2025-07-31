# R2-EmployeeSelfService Anti-Gaming Reminders - Employee Portal Compliance

**Purpose**: MANDATORY reminders to prevent gaming behaviors specific to Vue.js employee portal testing  
**Status**: Must be referenced before claiming ANY scenario complete  
**Authority**: META-R Systematic Completion Framework + R_AGENTS_COMMON.md  
**R2-Specific Context**: Dual-portal testing with permission limitations

## 🚨 ABSOLUTE PROHIBITIONS

### ❌ NEVER DO THESE THINGS

#### Employee Portal Cross-Referencing (PROHIBITED)
```
❌ "Calendar exists, so request creation must work"
❌ "Notification list loads, so notification actions are complete"
❌ "Exchange tab exists, so exchange creation is functional"
❌ "Vue.js interface loads, so all Vue.js features work"
❌ "Admin portal has feature X, so employee portal has it too"
```

#### Permission Assumption Gaming (PROHIBITED)
```
❌ "test/test user can see menu item, so functionality is complete"
❌ "Form loads, so form submission works"
❌ "API exists in admin portal, so employee portal uses same API"
❌ "Feature works for Konstantin user, so it works for test user"
❌ "Similar to admin portal, marking employee portal as complete"
```

#### Vue.js vs PrimeFaces Confusion Gaming (PROHIBITED)
```
❌ "PrimeFaces admin portal behavior applies to Vue.js employee portal"
❌ "Session timeout patterns are identical between portals"
❌ "Form validation rules are the same across frameworks"
❌ "URL routing works identically in SPA vs traditional pages"
```

#### Form Validation Gaming (PROHIBITED)
```
❌ "Form fields exist, so form submission is complete"
❌ "No visible errors, so validation is working"
❌ "Similar form in admin portal works, so employee form works"
❌ "Calendar date selected, so date validation is satisfied"
❌ "Tested with different date format, covering all validation scenarios"
```

#### Architectural Assumption Gaming (PROHIBITED)
```
❌ "Profile URL returns 404, but profile functionality exists somewhere"
❌ "Exchange creation not visible, but must be available to employees"
❌ "Logout URL returns 404, but logout functionality implied"
❌ "Feature missing from employee portal, but marking as architectural parity"
```

## ✅ MANDATORY REQUIREMENTS (Each Scenario)

### R2-Specific Evidence Chain (ALL REQUIRED)
1. **Direct MCP Navigation**: `mcp__playwright-human-behavior__navigate → [exact employee portal URL]`
2. **User Context Verification**: Confirm test/test user vs Konstantin/12345 permissions
3. **Vue.js Interaction**: Actual clicks, typing, SPA navigation
4. **Dual-Portal Comparison**: Test same functionality on both portals when relevant
5. **Live Operational Data**: Real notifications, acknowledgments, timestamps
6. **Framework-Specific Evidence**: Vue.js reactivity, SPA routing, component behavior
7. **Permission Documentation**: What works vs blocked for each user type

### Employee Portal Quality Verification Checklist
```
□ Did I test this specific feature on employee portal (Vue.js)?
□ Did I compare behavior with admin portal (PrimeFaces) when relevant?
□ Did I verify user permissions (test/test vs Konstantin/12345)?
□ Did I capture Vue.js-specific behavior (SPA routing, reactivity)?
□ Did I document live operational data (not mock data)?
□ Did I test form validation with actual submission attempts?
□ Did I document Russian UI text from Vue.js interface?
□ Did I note architectural differences (SPA vs traditional pages)?
□ Can someone reproduce this test with the exact same user?
```

## 🎯 EMPLOYEE PORTAL TESTING INDEPENDENCE

### Portal Isolation Rules
- **Employee Portal** (Vue.js) ≠ **Admin Portal** (PrimeFaces)
- **test/test permissions** ≠ **Konstantin/12345 permissions**
- **SPA routing** ≠ **Traditional page navigation**
- **Vue.js components** ≠ **PrimeFaces components**
- **Auto-authentication** ≠ **Manual login required**

### No Portal Inheritance Logic
```
❌ "Admin portal has role management, so employee portal has self-role management"
❌ "Konstantin can create requests, so test user can create requests"
❌ "PrimeFaces validation works, so Vue.js validation works identically"
❌ "Admin session timeout at 30 minutes, so employee session identical"
❌ "Employee menu item exists, so feature is fully implemented"
```

## ⏱️ REALISTIC TIMING STANDARDS (R2-Specific)

### Minimum Time Per Employee Portal Scenario
- **Vue.js Navigation**: 3-4 minutes (faster loading than PrimeFaces)
- **Form Interaction with Validation**: 6-10 minutes (debugging validation blockers)
- **Dual-Portal Comparison**: 8-12 minutes (two authentication contexts)
- **Live Data Analysis**: 4-6 minutes (106+ notifications, acknowledgments)
- **SPA Behavior Testing**: 5-8 minutes (routing, state management)
- **Documentation**: 3-4 minutes per scenario (dual-context evidence)

### Red Flag Timing Patterns (R2-Specific)
```
🚨 8 scenarios in 30 minutes with dual-portal testing = Gaming
🚨 "Tested all request scenarios" in 1 hour without form resolution = Gaming  
🚨 "Profile functionality complete" when profile returns 404 = Gaming
🚨 Request form validation "resolved" without showing successful submission = Gaming
🚨 "Exchange creation complete" without evidence of creation interface = Gaming
```

## 📝 R2-SPECIFIC EVIDENCE DOCUMENTATION STANDARDS

### Required Evidence Format (Each Employee Portal Scenario)
```markdown
SCENARIO: [Exact BDD scenario name]
PORTAL: Employee Portal (Vue.js + Vuetify)
USER: test/test (employee permissions)

MCP_SEQUENCE:
  1. mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/[path]
     RESULT: [Vue.js loading, auto-auth status, page title]
  2. mcp__playwright-human-behavior__[action] → [Vue.js selector] → [input]
     RESULT: [Vue.js reactivity, validation response, state change]
  3. mcp__playwright-human-behavior__get_content → humanReading: true
     RESULT: [Russian UI text from Vue.js components]

LIVE_OPERATIONAL_DATA:
  - Notifications: [106+ real notifications with timestamps]
  - Acknowledgments: [Live data changes: "Новый" → "Ознакомлен(а)"]
  - User_Context: test user (limited permissions)
  - Russian_Text: "[exact Vue.js interface quotes]"

DUAL_PORTAL_COMPARISON:
  - Employee Portal (test/test): [specific behavior observed]
  - Admin Portal (Konstantin/12345): [compared behavior, if tested]
  - Permission Difference: [what each user can/cannot access]

FRAMEWORK_SPECIFIC:
  - Vue.js SPA Routing: [client-side navigation behavior]
  - Session Persistence: [better than PrimeFaces admin portal]
  - Component Reactivity: [Vue.js state management observed]

VALIDATION_TESTING: 
  - Form Fields Attempted: [#input-181, #input-198, #input-245]
  - Validation Messages: ["Поле должно быть заполнено", etc.]
  - Submission Result: [Success/Failed with specific error]

ERROR_ENCOUNTERED: [Specific error OR "Working as expected"]
BLOCKER_STATUS: [Active blocker/Resolved/User-dependent]
```

## 🚫 R2-SPECIFIC GAMING BEHAVIORS (AVOID)

### Request Form Validation Gaming
- **Wrong**: "Filled all visible fields, so form submission is complete"
- **Right**: "Filled all fields but validation persists - blocked on hidden requirements"

### Profile Feature Gaming
- **Wrong**: "Profile URL returns 404 but user management exists, so profile is complete"
- **Right**: "Profile URL returns 404 - profile functionality not implemented for employees"

### Exchange System Gaming
- **Wrong**: "Exchange tabs exist, so exchange functionality is complete"
- **Right**: "Exchange tabs show structure but no creation interface for test user"

### Vue.js vs PrimeFaces Gaming
- **Wrong**: "Admin portal works this way, so employee portal works identically"
- **Right**: "Employee portal (Vue.js) behaves differently from admin portal (PrimeFaces)"

### Live Data Gaming
- **Wrong**: "System shows data, so all data interactions work"
- **Right**: "System shows 106+ notifications, tested specific interactions with live results"

## 📊 HONEST PROGRESS TRACKING (R2-Specific)

### Current Honest Status
- **Verified with Evidence**: 34/57 scenarios (59.6%)
- **Critical Blocker**: Request form validation (affects 8+ scenarios)
- **Architecture Limitations**: Profile (404), exchange creation (no interface)
- **User Permission Blocks**: test/test vs Konstantin/12345 differences

### Update Frequency Rules (R2-Specific)
- **After each scenario**: Update count only with complete MCP evidence
- **With dual-portal context**: Include permission comparison when relevant
- **With framework notes**: Vue.js vs PrimeFaces behavioral differences
- **With blocker status**: Active blockers vs resolved vs user-dependent

### Progress Reporting Standards (R2-Specific)
```
✅ GOOD: "Completed Scenario 21 (Navigate to Notifications) - 106+ live notifications verified"
❌ BAD: "Completed scenarios 21-24 (notification system) - all working"

✅ GOOD: "34/57 scenarios (59.6%) with complete employee portal evidence"
❌ BAD: "52/57 scenarios (91%) - comprehensive dual-portal testing complete"

✅ GOOD: "Request form blocked - validation persists despite all visible fields"
❌ BAD: "Request system complete - form loads and submits successfully"

✅ GOOD: "Profile returns 404 - not implemented for employee users"
❌ BAD: "Profile functionality complete - integrated within other pages"
```

## 🎯 META-R SUBMISSION INTEGRITY (R2-Specific)

### R2 Submission Quality Standards
- **Employee portal evidence only** - no cross-portal assumptions
- **User permission context** - test/test limitations documented
- **Vue.js behavior patterns** - SPA routing, component reactivity
- **Live operational data** - real notifications, acknowledgments, timestamps
- **Framework comparisons** - Vue.js vs PrimeFaces differences when relevant
- **Honest blocker documentation** - request form validation, profile 404, etc.

### R2 Review Preparation
- **Can META-R access employee portal with test/test credentials?**
- **Are Vue.js-specific behaviors documented clearly?**
- **Is request form validation blocker reproducible?**
- **Are architectural limitations (profile 404) documented honestly?**
- **Does submission show actual vs expected employee portal capabilities?**

## 🔴 CONSEQUENCES OF R2-SPECIFIC GAMING

### Request Form Validation Gaming
- **Reality Check**: Form validation still fails after multiple sessions
- **Gaming Consequence**: False completion claims will be easily verified
- **Meta-R Verification**: Can reproduce validation failure immediately

### Permission Assumption Gaming
- **Reality Check**: test/test user has limited permissions vs Konstantin/12345
- **Gaming Consequence**: Admin portal capabilities don't exist for employees
- **Meta-R Verification**: Direct testing shows permission limitations

### Architectural Feature Gaming
- **Reality Check**: Profile returns 404, exchange creation not visible
- **Gaming Consequence**: Claiming complete when features don't exist
- **Meta-R Verification**: 404 responses and missing interfaces easily verified

---

## 🎯 REMEMBER: EMPLOYEE PORTAL REALITY TESTING

**34/57 with honest evidence > 52/57 with permission assumptions**

Employee portal has different capabilities than admin portal.  
Vue.js behaves differently than PrimeFaces.  
test/test user has different permissions than Konstantin/12345.  

**Test employee portal reality. Document Vue.js behavior. Build on actual capabilities.**