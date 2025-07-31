# R3-ForecastAnalytics Session Ready Checklist

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

### Step 3: Forecast Module Access Test (3 minutes)
```bash
# Test if we can access forecast data input
mcp__playwright-human-behavior__navigate → /ccwfm/views/forecast/ForecastDataInput.xhtml
# Expected: Forecast interface displayed or timeout error
```

## 🎯 PRIORITY SCENARIO QUEUE (Ready to Execute)

### HIGH PRIORITY (Demo Value 5) - Do First

1. **Scenario 01: Forecast Data Input Access**
   - URL: `/ccwfm/views/forecast/ForecastDataInput.xhtml`
   - Expected: Tab 1 (Данные) interface with input forms
   - Evidence: Screenshot, Russian labels, form structure

2. **Scenario 02: Historical Data Import**  
   - Dependency: Scenario 01 success
   - Action: Navigate to Tab 2 (Импорт)
   - Evidence: Upload interface, validation messages, file format requirements

3. **Scenario 04: Forecast Algorithm Selection**
   - Action: Navigate to Tab 4 (Прогноз)
   - Expected: Algorithm dropdown with options
   - Evidence: Available algorithms, parameter settings

### MEDIUM PRIORITY (Demo Value 3-4) - Do Second
4. **Scenario 06: Analytics Dashboard Access**
5. **Scenario 05: Forecast Results Display** (Tab 5 - Результаты)
6. **Scenario 07: Report Generation Interface** (Tab 6 - Отчеты)

## 🔄 7-TAB WORKFLOW CRITICAL SEQUENCE

### Tab Navigation Order (MANDATORY)
1. **Tab 1**: Данные (Data/Input) - Entry point
2. **Tab 2**: Импорт (Import) - Data loading
3. **Tab 3**: Обработка (Processing) - Data processing
4. **Tab 4**: Прогноз (Forecasting) - Algorithm selection
5. **Tab 5**: Результаты (Results) - Forecast output
6. **Tab 6**: Отчеты (Reports) - Report generation
7. **Tab 7**: Экспорт (Export) - Data export

### Navigation Testing Pattern
```bash
# For each scenario requiring tab access:
mcp__playwright-human-behavior__click → .tab-[tab-name]
mcp__playwright-human-behavior__wait_and_observe → .[tab-content] → 5000
# Document tab state before proceeding
```

## 📝 LIVE EVIDENCE TEMPLATE (Copy-Paste Ready)

```markdown
## SCENARIO: [Name] (R3-ForecastAnalytics)

**BDD_FILE**: forecast-analytics.feature  
**TIMESTAMP**: [Current time]  
**SESSION**: R3 Forecast Documentation

### MCP_EVIDENCE:
1. **Navigate to Forecast Module**: 
   - Command: `mcp__playwright-human-behavior__navigate → [URL]`
   - Result: [Page title, interface load status]

2. **Tab Navigation** (if applicable):
   - Command: `mcp__playwright-human-behavior__click → .tab-[name]`
   - Result: [Tab activation, content loading]

3. **Interface Documentation**:
   - Command: `mcp__playwright-human-behavior__wait_and_observe → [selector] → 5000`
   - Result: [Interface elements loaded, timeouts]

4. **Capture Evidence**:
   - Command: `mcp__playwright-human-behavior__screenshot → fullPage: true`
   - Command: `mcp__playwright-human-behavior__get_content → includeHTML: false`
   - Result: [Visual and text evidence captured]

5. **Interactive Testing** (if forms/controls present):
   - Command: `mcp__playwright-human-behavior__click → [selector]`
   - Command: `mcp__playwright-human-behavior__type → [selector] → [value]`
   - Result: [Form responses, validation, errors]

### LIVE_DATA:
- **Argus_Timestamp**: [From system interface, not local]
- **Forecast_Job_ID**: [Any auto-generated forecast job IDs]
- **Russian_Interface_Text**: "[exact quote 1]", "[exact quote 2]", "[exact quote 3]"
- **Tab_Sequence**: [Which tabs accessed in order]
- **Data_Loading_Time**: [Seconds for heavy forecast operations]

### TAB_WORKFLOW_STATUS:
- **Current_Tab**: [Tab number and Russian name]
- **Previous_Tabs_Required**: [Dependencies for this scenario]
- **Next_Tab_Available**: [Whether progression is possible]

### ERROR_ENCOUNTERED:
[Session timeout, tab navigation failure, data loading error, or "None - working as expected"]

### REALITY_vs_BDD:
[How Argus forecast workflow differs from BDD specification, especially tab dependencies]

**STATUS**: ✅ COMPLETE | ⚠️ PARTIAL | ❌ BLOCKED

---
```

## ⏱️ R3-SPECIFIC SESSION TIMING TARGETS

### 90-Minute Session Plan
- **Minutes 0-10**: Startup, login, forecast module access verification
- **Minutes 10-75**: Systematic scenario testing (4-5 scenarios)
- **Minutes 75-85**: Document evidence, update progress with tab workflow notes
- **Minutes 85-90**: Plan next session, handle timeouts

### Per-Scenario Timing (Forecast-Adjusted)
- **Simple navigation scenarios**: 5-8 minutes (account for tab loading)
- **Data import/processing scenarios**: 8-12 minutes (heavy operations)
- **Complex forecast scenarios**: 12-18 minutes (algorithm processing time)
- **Documentation per scenario**: 3-4 minutes (include tab workflow)

### Expected Output per Session
- **Conservative**: 4 scenarios with complete tab workflow evidence
- **Target**: 5 scenarios with quality Russian terminology
- **Stretch**: 6 scenarios if no technical issues or heavy processing

## 🚨 R3-SPECIFIC ISSUE RESPONSES

### Session Timeout During Forecast Processing
**Pattern**: "Время жизни страницы истекло" during long calculations  
**Response**: 
1. Note which tab/operation caused timeout
2. Re-login immediately (Konstantin/12345)
3. Navigate back to last successful tab
4. Document processing time limitations

### Tab Navigation Failure
**Pattern**: Clicking tab doesn't activate or loads empty content  
**Response**:
1. Screenshot the failed tab state
2. Try refreshing page and re-login
3. Start from Tab 1 and progress sequentially
4. Document tab dependency requirements

### Heavy Data Loading Delays  
**Pattern**: Forecast calculations taking 30+ seconds  
**Response**:
1. Use extended wait times: `wait_and_observe → [selector] → 30000`
2. Document actual processing time
3. Don't mark as failed until 45+ seconds
4. Note system performance characteristics

### Russian Forecast Terminology Complexity
**Pattern**: Technical forecast terms not in general glossary  
**Response**:
1. Screenshot all Russian forecast interface text
2. Document exact terms with context
3. Build forecast-specific glossary
4. Note mathematical/technical term usage

## 📊 R3 PROGRESS TRACKING

### Update progress/status.json After Each Session
```json
{
  "agent": "R3-ForecastAnalytics",
  "scenarios_completed": [current_number],
  "scenarios_total": 37,
  "completion_percentage": "[calculated]%",
  "last_updated": "[timestamp]",
  "last_scenario": "[specific scenario name]",
  "session_count": [increment],
  "evidence_quality": "Gold Standard",
  "tab_workflow_documented": true,
  "forecast_processing_patterns": ["documented patterns"],
  "blockers": ["specific blockers found"],
  "next_session_priority": "[next 2-3 scenarios to test]"
}
```

### R3-Specific Progress Metrics
- **Tab Workflow Understanding**: Document 7-tab sequence
- **Russian Forecast Terms**: Build comprehensive glossary
- **Processing Time Patterns**: Note heavy operation timings
- **Algorithm Discovery**: Document available forecast algorithms

### META-R Submission Every 5 Scenarios
- Emphasize tab workflow requirements in submissions
- Include processing time documentation
- Show forecast-specific Russian terminology
- Demonstrate understanding of algorithmic complexity

## 📋 FORECAST MODULE SPECIFIC CHECKS

### Pre-Session Verification
- [ ] Can access main forecast data input interface
- [ ] Tab navigation responsive (all 7 tabs clickable)
- [ ] No immediate session timeouts
- [ ] Russian interface text displaying properly

### During Session Quality Checks
- [ ] Document exact tab progression for each scenario
- [ ] Capture Russian forecast terminology with translations
- [ ] Note processing times for heavy operations
- [ ] Screenshot tab states showing active/inactive status

### Post-Session Documentation
- [ ] All scenarios include tab workflow context
- [ ] Processing delays documented with actual timings
- [ ] Russian terms added to forecast glossary
- [ ] Tab dependencies mapped for future sessions

## ✅ R3 SESSION END CHECKLIST

- [ ] Progress updated honestly with realistic completion percentages
- [ ] Tab workflow patterns documented for attempted scenarios
- [ ] Screenshots captured showing forecast interface states
- [ ] Russian forecast terminology recorded with context
- [ ] Processing time limitations documented
- [ ] Tab navigation dependencies mapped
- [ ] Blockers identified with specific tab/operation context
- [ ] Next session priorities planned with tab sequence considerations
- [ ] META-R submission prepared if 5+ scenarios completed

**Ready for immediate R3-ForecastAnalytics testing when MCP tools available!**