# R1-AdminSecurity Session Ready Checklist

## 🚀 IMMEDIATE STARTUP SEQUENCE (When MCP Available)

### Step 1: Verify MCP Access (2 minutes)
```bash
# Test basic navigation
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
# Expected: "Аргус WFM CC" title, login form visible
```

### Step 2: Standard Login (3 minutes)  
```bash
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"
mcp__playwright-human-behavior__click → button[type="submit"]
# Expected: Successfully logged into admin portal
```

### Step 3: Quick Access Test (2 minutes)
```bash
# Test if we can access role management
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/RoleListView.xhtml
# Expected: Role list displayed or timeout error
```

## 🎯 PRIORITY SCENARIO QUEUE (Ready to Execute)

### HIGH PRIORITY (Demo Value 5) - Do First
1. **Scenario 11: Role List Display**
   - URL: `/ccwfm/views/env/security/RoleListView.xhtml`
   - Expected: Table with existing roles
   - Evidence: Screenshot, role count, Russian headers

2. **Scenario 26: Employee List Display**  
   - URL: `/ccwfm/views/env/personnel/WorkerListView.xhtml`
   - Expected: Employee table with ~513 employees
   - Evidence: Screenshot, employee count, department data

3. **Scenario 12: Create New Role**
   - Depends on: Scenario 11 success
   - Action: Click "Создать новую роль" button
   - Evidence: Form, Role-ID generation, Russian labels

### MEDIUM PRIORITY (Demo Value 3-4) - Do Second
4. **Scenario 27: Create New Employee**
5. **Scenario 46: System Configuration Access** (expect 403)
6. **Scenario 61: System Monitoring Dashboard**

## 📝 LIVE EVIDENCE TEMPLATE (Copy-Paste Ready)

```markdown
## SCENARIO: [Name]

**BDD_FILE**: admin-security.feature  
**TIMESTAMP**: [Current time]  
**SESSION**: R1 Systematic Testing

### MCP_EVIDENCE:
1. **Navigate**: 
   - Command: `mcp__playwright-human-behavior__navigate → [URL]`
   - Result: [Page title, status, redirects]

2. **Observe Interface**:
   - Command: `mcp__playwright-human-behavior__wait_and_observe → body → 3000`
   - Result: [What loaded, timeouts, errors]

3. **Capture Evidence**:
   - Command: `mcp__playwright-human-behavior__screenshot → fullPage: true`
   - Command: `mcp__playwright-human-behavior__get_content → humanReading: true`
   - Result: [Visual evidence, text content extracted]

4. **Interactive Testing** (if applicable):
   - Command: `mcp__playwright-human-behavior__click → [selector]`
   - Command: `mcp__playwright-human-behavior__type → [selector] → [text]`
   - Result: [Form responses, validation, success/error]

### LIVE_DATA:
- **Timestamp**: [From Argus system]
- **Unique_ID**: [Any auto-generated IDs like Role-XXXXX]
- **Russian_Text**: "[quote 1]", "[quote 2]", "[quote 3]"
- **User_Context**: Konstantin (admin) authenticated
- **Browser_State**: [Any special conditions]

### ERROR_ENCOUNTERED:
[Specific error message, timeout, 403/404, or "None - working as expected"]

### REALITY_vs_BDD:
[How actual Argus behavior differs from BDD specification]

**STATUS**: ✅ COMPLETE | ⚠️ PARTIAL | ❌ BLOCKED

---
```

## ⏱️ SESSION TIMING TARGETS

### 90-Minute Session Plan
- **Minutes 0-10**: Startup, login, access verification
- **Minutes 10-70**: Systematic scenario testing (6-8 scenarios)
- **Minutes 70-85**: Document evidence, update progress
- **Minutes 85-90**: Plan next session, handle any timeouts

### Per-Scenario Timing
- **Simple scenarios** (URL testing): 3-5 minutes
- **Interactive scenarios** (forms, clicks): 5-8 minutes  
- **Complex scenarios** (multi-step): 8-12 minutes
- **Documentation per scenario**: 2-3 minutes

### Expected Output per Session
- **Conservative**: 5 scenarios with complete evidence
- **Target**: 7 scenarios with quality documentation
- **Stretch**: 10 scenarios if no technical issues

## 🚨 COMMON ISSUE RESPONSES

### Session Timeout
**Pattern**: "Время жизни страницы истекло"  
**Response**: 
1. Note timeout duration
2. Re-login immediately (Konstantin/12345)
3. Continue from last completed scenario
4. Document session management pattern

### 403 Forbidden Error
**Pattern**: Access denied to admin functions  
**Response**:
1. Screenshot the 403 page
2. Document exact Russian error text
3. Mark scenario as "Super Admin Required"
4. Move to next scenario

### Network Connection Issues
**Pattern**: ERR_PROXY_CONNECTION_FAILED  
**Response**:
1. Save all current work immediately
2. Wait 30 seconds
3. Test basic navigation
4. Continue or plan next session if persistent

### Missing Features
**Pattern**: Expected interface doesn't exist  
**Response**:
1. Check alternative URLs/menu paths
2. Document as "Architecture Mismatch"
3. Note in reality vs BDD comparison
4. Don't inflate completion count

## 📊 PROGRESS TRACKING

### Update progress/status.json After Each Session
```json
{
  "scenarios_completed": [current_number],
  "last_updated": "[timestamp]",
  "last_scenario": "[specific scenario name]",
  "session_count": [increment],
  "evidence_quality": "Gold Standard",
  "blockers": ["specific blockers found"],
  "next_session_priority": "[next 2-3 scenarios to test]"
}
```

### Create META-R Submission Every 5 Scenarios
- Use evidence template above
- Submit batch for review
- Wait for feedback before continuing
- Maintain quality over quantity

## ✅ SESSION END CHECKLIST

- [ ] Progress updated honestly in status.json
- [ ] Evidence documented for all attempted scenarios  
- [ ] Screenshots and content saved
- [ ] Russian text recorded with translations
- [ ] Blockers identified and documented
- [ ] Next session priorities planned
- [ ] META-R submission prepared (if 5+ scenarios)

**Ready for immediate execution when MCP tools available!**