# R3-ForecastAnalytics Anti-Gaming Reminders - Critical Compliance

**Purpose**: MANDATORY reminders to prevent gaming behaviors and maintain evidence integrity  
**Status**: Must be referenced before claiming ANY scenario complete  
**Authority**: META-R Systematic Completion Framework + R_AGENTS_COMMON.md  
**R3-Specific**: Forecast module complexity requires extra vigilance against shortcuts

## 🚨 ABSOLUTE PROHIBITIONS

### ❌ NEVER DO THESE THINGS

#### Tab Workflow Shortcuts (PROHIBITED)
```
❌ "Tab 1 works, so all tabs must work"
❌ "Similar forecast interface in Tab 4, so Tab 5 complete"
❌ "Navigation works, so forecast functionality complete"
❌ "Saw algorithm dropdown, marking all forecast scenarios done"
```

#### Processing Time Assumptions (PROHIBITED)
```
❌ "Forecast would process if I waited, marking complete"
❌ "Similar calculation in other module, this one works too"
❌ "Algorithm exists, so results must be generated"
❌ "Interface loaded, functionality must be working"
```

#### Cross-Module Inference (PROHIBITED)
```
❌ "Analytics dashboard exists, so forecast analytics work"
❌ "Report templates visible, so report generation complete"
❌ "Export button present, so data export functional"
❌ "Other modules have charts, forecast charts must work"
```

#### Russian Term Shortcuts (PROHIBITED)
```
❌ "Standard terms, don't need documentation"
❌ "Similar to other Russian interfaces, reusing translations"
❌ "Obvious forecast terms, marking terminology complete"
❌ "Can guess meaning, don't need exact text capture"
```

#### Batch Completion Gaming (PROHIBITED)
```
❌ Claiming multiple tab scenarios complete after testing one tab
❌ Marking forecast scenarios done based on data input success
❌ "Tested workflow pattern, all similar scenarios complete"
❌ "7-tab sequence understood, marking all tab scenarios done"
```

## ✅ MANDATORY REQUIREMENTS (Each Scenario)

### Evidence Chain (ALL REQUIRED FOR FORECAST SCENARIOS)
1. **Direct MCP Navigation**: `mcp__playwright-human-behavior__navigate → [Exact URL]`
2. **Tab Progression**: Document exact tab sequence used
3. **Interface Interaction**: Actual clicks, form inputs, button presses
4. **Processing Time**: Record actual wait times for forecast operations
5. **Response Capture**: Screenshot + content extraction with Russian text
6. **Algorithm Documentation**: Note available options and selections
7. **Error Documentation**: Exact timeout/error messages with Russian text

### R3-Specific Quality Verification Checklist
```
□ Did I navigate to the specific forecast interface URL?
□ Did I document the tab sequence required for this scenario?
□ Did I wait for actual processing completion (not assume it works)?
□ Did I capture the Russian forecast terminology with exact quotes?
□ Did I test the specific functionality (not just interface presence)?
□ Did I document processing times for heavy forecast operations?
□ Did I record any algorithm or parameter selections made?
□ Did I capture evidence of forecast results or calculation outputs?
□ Did I document how the 7-tab workflow affects this scenario?
□ Can someone else reproduce this exact test sequence?
```

## 🔄 7-TAB WORKFLOW INTEGRITY

### Tab Independence Rules
- **Tab 1** (Данные) ≠ **Tab 2** (Импорт) - separate testing required
- **Tab 4** (Прогноз) ≠ **Tab 5** (Результаты) - algorithm ≠ results
- **Tab 6** (Отчеты) ≠ **Tab 7** (Экспорт) - reports ≠ export
- **Interface exists** ≠ **Functionality works** - must test operations

### No Tab Inheritance Logic
```
❌ "Successfully navigated to Tab 1, so Tab 2-7 accessible"
❌ "Data input works, so processing and forecasting work"
❌ "Algorithm selection available, so forecast generation works"
❌ "Report templates visible, so report generation functional"
```

## ⏱️ REALISTIC TIMING STANDARDS (R3-Adjusted)

### Minimum Time Per Scenario (Forecast-Specific)
- **Simple Navigation**: 5-8 minutes (tab loading + Russian documentation)
- **Data Input/Import**: 8-12 minutes (forms + file handling + validation)
- **Algorithm Configuration**: 10-15 minutes (selection + parameters + processing wait)
- **Forecast Generation**: 15-25 minutes (heavy calculations + results documentation)
- **Report/Export**: 12-18 minutes (generation time + format testing)

### R3 Red Flag Timing Patterns
```
🚨 5 forecast scenarios in 30 minutes = Impossible (processing time alone)
🚨 Claiming all 7 tabs tested in single session = Gaming behavior
🚨 "Quick tab navigation test" covering multiple scenarios = Gaming
🚨 No correlation between scenario complexity and time spent = Gaming
```

## 📝 R3-SPECIFIC EVIDENCE DOCUMENTATION STANDARDS

### Required Evidence Format (Each Forecast Scenario)
```markdown
SCENARIO: [Exact BDD scenario name - R3 ForecastAnalytics]
TAB_WORKFLOW:
  - Starting_Tab: [Tab number and Russian name]
  - Required_Progression: [Previous tabs needed]
  - Tab_Navigation_Command: mcp__playwright-human-behavior__click → .tab-[name]
  - Tab_Load_Result: [Interface loaded, errors, timeouts]

MCP_SEQUENCE:
  1. mcp__playwright-human-behavior__navigate → [exact forecast URL]
     RESULT: [title, tab states, any redirects]
  2. mcp__playwright-human-behavior__click → .tab-[specific-tab]
     RESULT: [tab activation, content loading time]
  3. mcp__playwright-human-behavior__wait_and_observe → [selector] → [timeout]ms
     RESULT: [what loaded, processing status, Russian interface text]
  4. mcp__playwright-human-behavior__[action] → [selector] → [input]
     RESULT: [forecast operation result, processing time, validation]

LIVE_DATA:
  - Argus_Timestamp: [from system interface, not local machine]
  - Forecast_Job_ID: [any auto-generated forecast job IDs]
  - Processing_Time: [actual seconds for calculations]
  - Russian_Forecast_Terms: "[exact quote 1]", "[exact quote 2]", "[exact quote 3]"
  - Algorithm_Selected: [specific algorithm if applicable]
  - Tab_Dependencies: [which tabs required before this scenario works]

ERROR_ENCOUNTERED: [Session timeout, processing error, tab failure, OR "None - worked as expected"]
PROCESSING_STATUS: [Completed, Timeout, Failed, Partial]
REALITY_vs_BDD: [How Argus forecast workflow differs from BDD, especially tab requirements]
EVIDENCE_FILES: [screenshot names showing tab states and results]
```

### Forecast-Specific Quality Control Questions
```
1. Is this evidence reproducible by someone else following the tab sequence?
2. Are all MCP commands and processing times documented accurately?
3. Is Russian forecast terminology quoted exactly as seen?
4. Are processing delays documented honestly (not hidden as "working")?
5. Are algorithm selections and parameters documented specifically?
6. Are tab dependencies clearly explained for scenario reproduction?
7. Is forecast operation success/failure documented with actual evidence?
```

## 🚫 R3-SPECIFIC GAMING BEHAVIORS (AVOID)

### Tab Navigation Gaming
- **Wrong**: "All tabs clickable, marking tab scenarios complete"
- **Right**: "Each tab tested individually with specific functionality verification"

### Processing Time Gaming
- **Wrong**: "Would complete if I waited longer, marking as complete"
- **Right**: "Waited 30 seconds, got timeout error, documenting as blocked"

### Algorithm Assumption Gaming
- **Wrong**: "Algorithm dropdown exists, forecast generation must work"
- **Right**: "Tested algorithm selection, documented actual processing result"

### Russian Term Gaming
- **Wrong**: "Standard forecast terms, don't need exact documentation"
- **Right**: "Captured exact Russian text with context and translations"

### Workflow Pattern Gaming
- **Wrong**: "Understood 7-tab pattern, marking all workflow scenarios complete"
- **Right**: "Tested specific tab sequence required for each individual scenario"

## 📊 HONEST PROGRESS TRACKING (R3-SPECIFIC)

### Update Frequency Rules
- **After each scenario**: Update with specific tab/functionality tested
- **With processing evidence**: Include actual calculation/processing times
- **With tab workflow**: Document exact tab progression used
- **With Russian terms**: Include forecast-specific terminology captured

### R3 Progress Reporting Standards
```
✅ GOOD: "Completed Scenario 01 (Data Input) - Tab 1 interface documented - 12 minutes"
❌ BAD: "Completed scenarios 01-04 (data workflow) - 25 minutes"

✅ GOOD: "15/37 scenarios (41%) with complete MCP evidence and tab workflow"
❌ BAD: "32/37 scenarios (86%) - comprehensive forecast testing complete"

✅ GOOD: "Blocked on 3 scenarios due to 30+ second processing timeouts"
❌ BAD: "All forecast calculations work perfectly with proper algorithms"
```

## 🎯 META-R SUBMISSION INTEGRITY (R3-FOCUSED)

### Forecast-Specific Submission Quality Standards
- **Only submit scenarios with complete tab workflow evidence**
- **Include exact processing times for forecast operations**
- **Document all Russian forecast terminology with context**
- **Show actual algorithm selections and parameter configurations**
- **Provide reproducible tab sequences for each scenario**
- **Demonstrate real forecast processing results, not interface presence**

### R3 Review Preparation
- **Can META-R reproduce each forecast test exactly with tab sequence?**
- **Is processing time evidence sufficient to verify calculation claims?**
- **Are Russian forecast terms documented comprehensively?**
- **Does submission show actual forecast functionality, not just navigation?**

## 🔴 CONSEQUENCES OF GAMING (R3-AMPLIFIED)

### Forecast Complexity Enforcement
- **Processing time audits**: Forecast operations require realistic time
- **Tab workflow verification**: Must demonstrate proper sequence understanding
- **Algorithm testing validation**: Must show actual forecast configuration/results
- **Russian terminology audit**: Forecast terms require exact documentation
- **Completion reset risk**: False claims about complex forecasting trigger restart

### R3-Specific Professional Standards
- **Processing integrity**: Don't claim completion without actual processing evidence
- **Tab workflow honesty**: Document exact requirements and dependencies
- **Algorithm transparency**: Show what was actually tested vs assumed working
- **Terminology precision**: Forecast Russian terms require exact capture and translation

---

## 🎯 R3 REMEMBER: COMPLEXITY REQUIRES EXTRA HONESTY

**25% with solid forecast evidence > 90% with tab navigation gaming**

Forecast scenarios are inherently complex with:
- 7-tab workflow dependencies
- Heavy processing time requirements  
- Specialized Russian terminology
- Algorithm configuration complexity

Each scenario completed honestly with full tab workflow evidence contributes to the project.  
Each scenario gamed with shortcuts undermines forecast documentation credibility.

**Test tab sequences. Document processing times. Capture Russian terms. Build systematically.**