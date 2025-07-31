# R2-EmployeeSelfService Dual Portal Testing Guide

**Purpose**: Systematic approach to testing employee portal vs admin portal for request form resolution  
**R2-Specific**: Employee self-service features across Vue.js and PrimeFaces architectures  
**Critical Blocker**: Request form validation - requires cross-portal comparison  

## 🏗️ PORTAL ARCHITECTURE OVERVIEW

### Employee Portal (Vue.js + Vuetify)
- **URL**: https://lkcc1010wfmcc.argustelecom.ru/
- **Credentials**: test/test (auto-authentication ~90% success)
- **Framework**: Vue.js SPA with client-side routing
- **Features**: Calendar, requests, notifications, acknowledgments, exchange
- **Limitations**: Profile (404), exchange creation (no interface)

### Admin Portal (PrimeFaces)
- **URL**: https://cc1010wfmcc.argustelecom.ru/ccwfm/
- **Credentials**: Konstantin/12345 (see @../R1/CLAUDE.md for login patterns)
- **Framework**: Traditional PrimeFaces with page reloads
- **Features**: Full admin interface (see @../R1/COMPLETE_88_SCENARIOS_DETAILED_PLAN.md)
- **Employee Management**: May include employee request creation

## 🎯 R2 DUAL-PORTAL TESTING METHODOLOGY

### Phase 1: Employee Portal Baseline (Current State)
**Status**: 34/57 scenarios completed with MCP evidence
**Critical Blocker**: Request form validation persists despite all visible fields filled

### Phase 2: Admin Portal Request Testing (User Comparison)
```bash
# Login to admin portal
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
# Use R1 login sequence: @../R1/CLAUDE.md lines 25-35
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"
mcp__playwright-human-behavior__click → button[type="submit"]

# Test admin-side employee request management
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/personnel/request/UserRequestView.xhtml
```

### Phase 3: Cross-Portal Feature Comparison
**Employee Features in Admin Portal**: Test if admin can create requests FOR employees
**Admin Features Unavailable to Employees**: Document permission boundaries
**Form Validation Differences**: Compare validation rules across portals

## 🔍 R2-SPECIFIC COMPARISON POINTS

### Request Form Validation
**Employee Portal (Vue.js)**:
- Form fields: #input-181 (date), #input-198 (comment), #input-245 (reason)
- Validation: "Поле должно быть заполнено", "Заполните дату в календаре"
- Status: BLOCKED - validation persists despite all fields completed

**Admin Portal (PrimeFaces)**:
- Test: Equivalent request creation interface
- Compare: Field IDs, validation messages, submission behavior
- Goal: Determine if admin portal request creation works

### Session Management
**Employee Portal**: Better session persistence (Vue.js SPA)
**Admin Portal**: Session timeout patterns (see @../R1/CLAUDE.md lines 34-43)

### User Interface Patterns
**Employee Portal**: Vue.js components (v-text-field, v-select, v-tabs)
**Admin Portal**: PrimeFaces components (traditional HTML forms)

## 📋 SYSTEMATIC DUAL-PORTAL TEST PLAN

### Test 1: Request Form User Comparison
```bash
# Employee Portal Test
1. Login with test/test → Navigate to calendar → Click "Создать"
2. Fill all known fields → Submit → Document validation errors

# Admin Portal Test  
3. Login with Konstantin/12345 → Navigate to employee requests
4. Test equivalent form → Compare field requirements
5. Document differences in form behavior
```

### Test 2: Feature Availability Matrix
```bash
# Document for each feature:
Feature | Employee Portal (test/test) | Admin Portal (Konstantin/12345)
--------|----------------------------|--------------------------------
Request Creation | BLOCKED (validation) | Test needed
Profile Management | 404 Not Found | May exist as employee management
Exchange Creation | No interface | May exist as admin function
```

### Test 3: Alternative Credentials Testing
```bash
# Try alternative employee credentials on employee portal
mcp__playwright-human-behavior__type → input[type="text"] → "pupkin_vo"  
mcp__playwright-human-behavior__type → input[type="password"] → "Balkhash22"

# Test if different user has different permissions
```

## 🔧 RESOLUTION PATHWAYS

### Pathway 1: Admin Portal Request Creation
**Hypothesis**: Admin portal can create requests for employees
**Test**: Find employee request management in admin interface
**Success Criteria**: Form submission works in admin portal

### Pathway 2: Employee Portal User Permissions
**Hypothesis**: test/test user has insufficient permissions
**Test**: Alternative credentials (pupkin_vo/Balkhash22) or elevated permissions
**Success Criteria**: Different user can complete request form

### Pathway 3: Date Format Requirements
**Hypothesis**: Employee portal requires specific Russian date format
**Test**: DD.MM.YYYY vs YYYY-MM-DD vs DD/MM/YYYY
**Success Criteria**: Correct format enables form submission

### Pathway 4: Hidden Form Requirements
**Hypothesis**: Vue.js form has invisible validation requirements
**Test**: JavaScript analysis of all form fields and validation rules
**Success Criteria**: Identify missing required fields

## 📊 EVIDENCE COLLECTION FRAMEWORK

### Dual-Portal Evidence Template
```markdown
## FEATURE: [Request Creation / Profile Management / etc.]

### EMPLOYEE PORTAL (Vue.js)
- **URL**: https://lkcc1010wfmcc.argustelecom.ru/[path]
- **User**: test/test
- **Behavior**: [Exact behavior observed]
- **Status**: [Working/Blocked/404]
- **MCP Evidence**: [Commands and results]

### ADMIN PORTAL (PrimeFaces)  
- **URL**: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/[path]
- **User**: Konstantin/12345
- **Behavior**: [Exact behavior observed]
- **Status**: [Working/Blocked/403/404]
- **MCP Evidence**: [Commands and results]

### COMPARISON RESULT
- **Architecture Difference**: [Vue.js vs PrimeFaces behavioral differences]
- **Permission Difference**: [User access level differences]
- **Resolution Path**: [Which portal/user combination works]
```

## 🚨 COMMON DUAL-PORTAL PATTERNS

### Authentication Differences
- **Employee Portal**: Auto-authentication, session persistence
- **Admin Portal**: Manual login required, session timeouts (see @../R1/CLAUDE.md)

### Framework Behavior Differences
- **Vue.js SPA**: Client-side routing, component reactivity, graceful 404s
- **PrimeFaces**: Server-side rendering, page reloads, traditional form validation

### Error Handling Differences
- **Employee Portal**: "Упс..Вы попали на несуществующую страницу" (SPA 404)
- **Admin Portal**: Various error patterns (see @../R1/ANTI_GAMING_REMINDERS.md)

## 🎯 R2 SUCCESS METRICS

### Form Resolution Success
- **Request form validation resolved**: Unlocks 8+ dependent scenarios
- **Clear permission boundaries documented**: User capability matrix
- **Working request workflow established**: End-to-end process verified

### Dual-Portal Understanding
- **Architecture differences mapped**: Vue.js vs PrimeFaces patterns
- **Feature availability by user documented**: Employee vs admin capabilities
- **Cross-portal security boundaries verified**: Portal isolation confirmed

## 📋 NEXT SESSION PRIORITIES

1. **Admin portal employee request testing** (2-3 hours)
2. **Alternative credential testing** (1 hour)  
3. **Date format systematic testing** (1 hour)
4. **JavaScript form analysis** (1 hour)
5. **Permission matrix documentation** (30 minutes)

**Expected Outcome**: Request form blocker resolution or clear documentation of architectural limitations

This guide focuses specifically on R2's dual-portal testing needs while referencing R1's established patterns for admin portal testing procedures.