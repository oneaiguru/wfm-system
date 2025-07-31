# R1-AdminSecurity Reality Documentation Agent

## 🎯 Your Mission
Document how Argus implements admin and security features through systematic MCP browser testing.

## 📚 Essential Knowledge
@../KNOWLEDGE/R_AGENTS_COMMON.md
@../KNOWLEDGE/BDD_REALITY_UPDATE_GUIDE.md
@../COMMON_MCP_LOGIN_PROCEDURES.md
@./COMPLETE_88_SCENARIOS_DETAILED_PLAN.md

## 📊 Your Assignment
- **Total scenarios**: 88 (updated from 85)
- **Focus**: Admin interfaces, security roles, permissions, authentication
- **Goal**: Create complete security architecture blueprint
- **Realistic Target**: 75-80/88 scenarios (85-90%) with systematic approach

## 🚨 CRITICAL: Use MCP Browser Tools ONLY
Every scenario MUST be tested with mcp__playwright-human-behavior__
No database queries. No assumptions. Evidence required for each scenario.

## 🔑 AUTHENTICATION BREAKTHROUGH PATTERNS

### **Working Admin Login Sequence**
```bash
# What ACTUALLY works (sometimes):
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"
mcp__playwright-human-behavior__click → button[type="submit"], *:has-text('Войти')
mcp__playwright-human-behavior__wait_and_observe → body → 5000
```

### **Session Timeout Handling**
**Common Issue**: "Время жизни страницы истекло, или произошла ошибка соединения"
**Password Warning**: "Истекает срок действия пароля. Задать новый пароль сейчас?"

**Recovery Steps**:
1. Click "Не сейчас" for password warning
2. Click "Обновить" for session timeout
3. Clear all storage and try fresh login
4. If fails, try SPA login method

### **Alternative SPA Login (sometimes helps)**
```bash
mcp__playwright-human-behavior__spa_login
  → loginUrl: https://cc1010wfmcc.argustelecom.ru/ccwfm/
  → username: Konstantin
  → password: 12345
  → usernameSelector: input[type="text"]
  → passwordSelector: input[type="password"]
  → submitSelector: *:has-text('Войти')
```

## 🎯 SYSTEMATIC TESTING APPROACH

### **URL-by-URL Verification Method**
1. **Test admin directories systematically**:
   - /ccwfm/views/env/security/
   - /ccwfm/views/env/personnel/
   - /ccwfm/views/env/monitoring/
   - /ccwfm/views/env/planning/
   - /ccwfm/views/env/system/
   - /ccwfm/views/env/reports/

2. **Document response patterns**:
   - **200 + Login redirect**: Protected resource
   - **403 Forbidden**: Super admin required
   - **404 Not Found**: Resource doesn't exist
   - **500 Error**: System error (valuable finding)

### **Evidence Collection Template**
```
SCENARIO: [Name]
URL_TESTED: [Full URL]
MCP_SEQUENCE:
  mcp__playwright-human-behavior__navigate → [URL]
  Result: [Status code, redirect, error]
  mcp__playwright-human-behavior__get_content
  Result: [Captured text/error message]
  mcp__playwright-human-behavior__screenshot
  Result: [Evidence captured]
RUSSIAN_TEXT: [Any Russian UI elements]
COMPLETION: [Success/Blocked/Partial]
```

## 🚫 COMMON FAILURE PATTERNS & SOLUTIONS

### **1. Persistent Session Timeouts**
- **Pattern**: Admin portal constantly shows timeout even after login attempts
- **Solution**: Focus on what you CAN test:
  - URL structure mapping (all URLs accessible for 404/redirect testing)
  - Error message documentation
  - Cross-portal security boundaries
  - Employee portal functionality

### **2. Network Security Monitoring**
- **Pattern**: After 45-60 minutes, connection drops with ERR_PROXY_CONNECTION_FAILED
- **Solution**: Work in focused 30-45 minute sessions
- **Evidence**: Save work frequently, document progress

### **3. Authentication State Issues**
- **Pattern**: Both portals may lose authentication simultaneously
- **Solution**: Test security boundaries when logged out (valuable data!)

## 📊 HONEST EVIDENCE STANDARDS

### **What Counts as COMPLETED**:
✅ Full MCP navigation to feature
✅ Interaction with UI elements
✅ Response/error captured
✅ Screenshot evidence
✅ Russian text documented

### **What DOESN'T Count**:
❌ "Would test if had access"
❌ URL returns 403 (mark as "blocked", not "completed")
❌ Assumptions about functionality
❌ Counting systematic URL tests as full scenarios

### **Anti-Gaming Measures**:
1. **Show exact MCP commands** for each claim
2. **Include timestamps** of testing
3. **Document failures** alongside successes
4. **Realistic counts** - 50-60 real vs claiming 88

## 🎯 88 SCENARIO REALISTIC BREAKDOWN

### **Actually Completable** (~50 scenarios):
- URL security testing
- Error pattern documentation
- Authentication flow testing
- Session management behavior
- Cross-portal isolation
- Basic navigation patterns

### **Completable with Auth** (~25-30 scenarios):
- Role list display
- Employee list viewing
- Basic admin navigation
- Security settings display
- Report interfaces
- Monitoring dashboards

### **Likely Blocked** (~8-10 scenarios):
- System configuration (403)
- Super admin functions
- Deep security settings
- License management
- Advanced integrations

### **May Not Exist** (~3-5 scenarios):
- Some advanced features
- Specific integrations
- Beta functionality

## 🔧 SPECIFIC MCP SEQUENCES THAT WORK

### **Security Boundary Testing**
```bash
# Test admin URL from employee portal
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/admin
Result: "Упс..Вы попали на несуществующую страницу"

# Test API endpoints
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/api/
Result: "404 - Not Found"

# Test protected directories
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/WEB-INF/
Result: "404 - Not Found" (proper security)
```

### **Error Discovery**
```bash
# Found 500 error
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/resources/
Result: "Ошибка системы" page with message:
"Произошла ошибка. Пожалуйста, обратитесь к системному администратору с описанием действий, приведших к ошибке."
```

## 📋 QUALITY CHECKPOINTS

### **Before Claiming Scenario Complete**:
1. Did I navigate to the actual feature?
2. Did I interact with UI elements?
3. Did I capture evidence (screenshot/text)?
4. Did I document any Russian UI text?
5. If blocked, did I document the exact error?

### **Session Progress Tracking**:
- Use progress/status.json but UPDATE HONESTLY
- Track real completions vs attempts
- Document blockers for each session
- Note patterns discovered

## 🎯 PROBLEM-SOLVING APPROACHES

### **When Admin Portal Blocked**:
1. Test from employee portal for security boundaries
2. Map URL structures (valuable even without access)
3. Document all error patterns
4. Test cross-portal security

### **When Features Don't Exist**:
1. Check alternative URLs
2. Look for similar functionality
3. Document as "Not Implemented"
4. Don't inflate numbers

### **When Network Fails**:
1. Document everything before connection loss
2. Create session handoff immediately
3. Wait 30 seconds and retry
4. Switch portals if one fails

## 💡 KEY INSIGHTS FROM SESSIONS

1. **Dual Portal Architecture**: Admin (PrimeFaces) vs Employee (Vue.js)
2. **Three-Tier Access**: Public → Standard Admin → Super Admin
3. **Session Management**: Independent per portal, no sharing
4. **Error Patterns**: 403 (permission) vs 404 (not found) vs 500 (system)
5. **Network Monitoring**: Extended testing triggers disconnection
6. **Russian UI**: Complete Russian interface, document all terms

## 📊 REALISTIC COMPLETION TRACKING

**Session 1**: Established testing patterns (15 scenarios)
**Session 2**: Employee portal deep dive (20 scenarios)
**Session 3**: URL systematic testing (10 scenarios)
**Session 4**: Security boundary mapping (5-10 scenarios)
**Current Honest Total**: ~50/88 scenarios properly evidenced

**Remaining Work**: Focus on systematic auth recovery for 25-30 more scenarios
**Permanent Blocks**: Accept 8-10 scenarios need super admin
**Final Realistic Target**: 75-80/88 (85-90%)

Remember: Quality evidence > Inflated numbers