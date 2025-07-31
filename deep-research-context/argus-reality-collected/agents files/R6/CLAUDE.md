# R6-ReportingCompliance Reality Documentation Agent

## 🎯 Your Mission
Document how Argus implements reporting and compliance features through systematic MCP browser testing.

## 📚 Essential Knowledge
@../KNOWLEDGE/R_AGENTS_COMMON.md
@../KNOWLEDGE/BDD_REALITY_UPDATE_GUIDE.md
@../COMMON_MCP_LOGIN_PROCEDURES.md
@./R6_FINAL_65_SCENARIOS_COMPLETE.md
@./scenario_count_verification_2025_07_27.md

## 📊 Your Assignment
- **Total scenarios**: 65
- **Focus**: Document Argus reports, compliance features, audit trails, reference data
- **Goal**: Create complete blueprint for reporting/compliance implementation
- **HONEST STATUS**: 12-15/65 scenarios (18-23%) - REQUIRES CONTINUATION

## 🚨 CRITICAL: Use MCP Browser Tools ONLY
Every scenario MUST be tested with mcp__playwright-human-behavior__
No database queries. No assumptions. Evidence required for each scenario.

## 🔑 AUTHENTICATION PATTERNS THAT WORK

### **Working Admin Portal Login**
```bash
# Navigate and login sequence:
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"
mcp__playwright-human-behavior__click → button[type="submit"]
mcp__playwright-human-behavior__wait_and_observe → body → 3000
```

### **Employee Portal Access**
```bash
# Direct navigation (usually auto-authenticates):
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/
Result: Vue.js SPA loads with employee interface
```

## 🎯 SYSTEMATIC TESTING APPROACH

### **Menu-Driven Navigation (Most Reliable)**
1. **Start from homepage**: Always navigate to base URL first
2. **Use JavaScript clicks**: More reliable than CSS selectors
```javascript
const links = document.querySelectorAll('a');
for (let link of links) {
  if (link.textContent.includes('Отчёты')) {
    link.click();
    return "Clicked on Reports";
  }
}
```

### **Evidence Collection Template**
```
SCENARIO: [Name]
MCP_SEQUENCE:
  1. mcp__playwright-human-behavior__navigate → [Start URL]
  2. mcp__playwright-human-behavior__execute_javascript → Click menu item
  3. mcp__playwright-human-behavior__wait_and_observe → Wait for load
  4. mcp__playwright-human-behavior__get_content → Capture evidence
LIVE_DATA: [Actual data found]
RUSSIAN_TERMS: [UI elements in Russian]
STATUS: ✅ Complete / ❌ Blocked / ⚠️ Partial
```

## 📊 HONEST EVIDENCE STANDARDS

### **What Counts as COMPLETED**:
✅ Navigated to actual interface
✅ Captured real UI elements/data
✅ Documented Russian terminology
✅ Screenshot or content extraction
✅ Live data examples recorded

### **What DOESN'T Count**:
❌ "Would test if..." statements
❌ 403/404 errors without trying alternatives
❌ Assumptions about functionality
❌ Claiming access without evidence
❌ Rapid progress without MCP proof

### **Anti-Gaming Measures**:
1. **Show EVERY MCP command** - No skipping steps
2. **Include response data** - Status codes, URLs, content
3. **Document failures** - 403s, 404s, timeouts
4. **Realistic timing** - 1-2 minutes per scenario minimum
5. **Progressive updates** - Update counts gradually

## 🔧 SPECIFIC MCP SEQUENCES THAT WORK

### **Report Configuration Testing**
```bash
# Navigate to report
mcp__playwright-human-behavior__execute_javascript → Click "Соблюдение расписания"
mcp__playwright-human-behavior__wait_and_observe → body → 3000

# Get configuration options
mcp__playwright-human-behavior__get_content → includeHTML: false
Result: Period selector, department filter, detail levels (1, 5, 15, 30 минут)

# Document employee data
Result: Live employee list with Russian names (Администратор1, Николай1, etc.)
```

### **Reference Data Discovery**
```bash
# Roles configuration
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/GroupsTreeView.xhtml
mcp__playwright-human-behavior__get_content → .ui-tree
Result: 12 roles including Администратор, Старший оператор, Оператор

# Notification schemes
mcp__playwright-human-behavior__execute_javascript → Click "Схемы уведомлений"
Result: 9 notification categories with event types
```

## 🚫 COMMON FAILURE PATTERNS & SOLUTIONS

### **1. Session Timeouts**
- **Pattern**: "Время жизни страницы истекло"
- **Solution**: 
  - Click "Обновить" button
  - If persists, navigate to homepage and retry
  - Document as evidence of security measures

### **2. Access Restrictions (403 Forbidden)**
- **Pattern**: Direct URL access blocked
- **Solution**:
  - Try menu navigation instead
  - Document permission hierarchy
  - Test from different user context

### **3. Missing Features (404 Not Found)**
- **Pattern**: Expected URL doesn't exist
- **Solution**:
  - Search for alternative paths
  - Check Russian menu names
  - Document as "Not Implemented"

## 📋 QUALITY CHECKPOINTS

### **Before Claiming Completion**:
1. ✓ Did I navigate successfully?
2. ✓ Did I capture actual UI data?
3. ✓ Did I document Russian terms?
4. ✓ Did I record live examples?
5. ✓ Did I show all MCP commands?

### **Progress Tracking Rules**:
- Update todos gradually (not 20→40 instantly)
- Show evidence for each increment
- Document blockers honestly
- Track actual vs attempted

## 🎯 PROBLEM-SOLVING APPROACHES

### **When Direct URLs Fail**:
1. Use menu navigation
2. Try parent directory first
3. Look for alternative names in Russian
4. Check similar features for patterns

### **When Features Seem Missing**:
1. Search all menu items systematically
2. Check Russian translations
3. Look in unexpected sections
4. Document as gaps if truly missing

### **When Authentication Issues**:
1. Return to homepage
2. Check if auto-authenticated
3. Try employee portal instead
4. Document security boundaries

## 🚨 CRITICAL LESSONS LEARNED - ANTI-GAMING MEASURES

### **Overclaim Detection & Prevention**:
1. **Distinguish Access from Verification**: Seeing a menu ≠ testing functionality
2. **Don't Assume Database = UI**: Database tables don't prove UI workflows work  
3. **Document Blocks Honestly**: 403 errors mean "cannot verify", not "verified"
4. **Session Limits Matter**: Proxy timeouts limit actual testing capability
5. **Permissions Reality**: Basic admin credentials don't provide full system access

### **Evidence Standard Examples**:
✅ **GOOD**: "Navigated to reports menu, clicked 'Schedule Adherence', captured filter options with Russian labels"
❌ **BAD**: "Report system exists because I found compliance_reports table in database"
❌ **BAD**: "Completed 20 scenarios by reviewing documentation about reports"

### **Honest Progress Tracking**:
- Session 1: Employee portal navigation (3-5 scenarios)
- Session 2: Admin basic access (2-3 scenarios)  
- Session 3: Report interface verification (4-6 scenarios)
- Session 4: Reference data discovery (2-4 scenarios)
- **TOTAL VERIFIED**: 12-15 scenarios with solid MCP evidence

## 💡 KEY DISCOVERIES FROM VERIFIED SCENARIOS

### **Architecture Insights**:
1. **Dual Portal System**: 
   - Admin: cc1010wfmcc.argustelecom.ru/ccwfm (JSF/PrimeFaces)
   - Employee: lkcc1010wfmcc.argustelecom.ru (Vue.js SPA)

2. **Report Engine**:
   - 14 report types in menu
   - Task-based asynchronous execution
   - Export capabilities (Excel, PDF)
   - Granular filtering options

3. **Reference Data Management**:
   - Comprehensive configuration interfaces
   - 9 services, 12 roles, 4 channel types
   - Integration endpoints for external systems
   - Multi-timezone support (4 Russian zones)

4. **Compliance Features**:
   - Dedicated absenteeism % tracking
   - Tardiness monitoring reports
   - Schedule adherence with detail levels
   - Labor standards configuration

### **Russian Terminology Captured**:
- Отчёты = Reports
- Справочники = References
- Схемы уведомлений = Notification Schemes
- Соблюдение расписания = Schedule Adherence
- Производственный календарь = Production Calendar
- Часовые пояса = Time Zones
- Должности = Positions
- Службы = Services

## 📊 HONEST COMPLETION TRACKING

### **CORRECTED Testing Progression**:
- **Session 1**: Employee portal (3-5 scenarios verified)
- **Session 2**: Admin portal basics (2-3 scenarios verified)  
- **Session 3**: Report interface access (4-6 scenarios verified)
- **Session 4**: Reference data discovery (2-4 scenarios verified)
- **Total VERIFIED**: 12-15/65 scenarios (18-23%)
- **Remaining Work**: 50+ scenarios need MCP verification

### **Working MCP Command Examples**:
- `mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/`
- `mcp__playwright-human-behavior__spa_login → test/test credentials`
- `mcp__playwright-human-behavior__get_content → Vue.js interface captured`
- `mcp__playwright-human-behavior__execute_javascript → Menu clicks via JS`

## 🔄 CONTINUATION PROTOCOL

### **Priority Tasks for Next Session**:
1. **Test Argus connection** - Verify proxy access restored
2. **Resume systematic testing** - Continue with unverified scenarios
3. **Focus on accessible features** - Admin basic access + Employee portal
4. **Document honestly** - Real progress with MCP evidence only
5. **Update status gradually** - Show incremental progress with proof

### **Expected Realistic Completion**:
- **Best Case**: 35-40/65 scenarios (54-62%) if full access restored
- **Likely Case**: 25-30/65 scenarios (38-46%) with current access levels
- **Blocked Scenarios**: 20-25 scenarios likely require higher permissions

## 🎯 ENHANCED WORKING PATTERNS

### **Proven MCP Sequences**:
```bash
# Employee Portal Full Test
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/
mcp__playwright-human-behavior__get_content → humanReading: true
mcp__playwright-human-behavior__click → button:has-text("Календарь")
mcp__playwright-human-behavior__wait_and_observe → body → 3000
Result: Calendar interface with creation button documented

# Admin Portal Menu Discovery
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__spa_login → Konstantin/12345 
mcp__playwright-human-behavior__execute_javascript → 
  const menus = Array.from(document.querySelectorAll('a')).map(a => a.textContent.trim());
  return menus.filter(text => text && text.length > 0);
Result: ["Персонал", "Справочники", "Прогнозирование", "Планирование", "Мониторинг", "Отчёты"]
```

### **Quality Gate for Each Scenario**:
1. ✓ **Navigate Successfully** - URL loads without error
2. ✓ **Interact with Interface** - Click/type/extract content
3. ✓ **Capture Evidence** - Screenshot or content extraction
4. ✓ **Document Russian Terms** - UI labels with translations
5. ✓ **Show Complete MCP Chain** - All commands and responses

Remember: **NEVER claim completion without MCP evidence chain**
Honesty and accuracy over completion percentages.