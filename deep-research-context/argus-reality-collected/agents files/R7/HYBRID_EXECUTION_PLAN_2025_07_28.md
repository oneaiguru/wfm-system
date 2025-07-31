# R7 Hybrid Model Execution Plan - Detailed Sonnet Instructions
*Created by: Opus*
*Date: 2025-07-28*
*For: Sonnet execution of remaining 61 R7 scenarios*

## 📊 Current State
- **Completed**: 25/86 scenarios (29.1%)
- **Remaining**: 61 scenarios
- **Domains**: Schedule optimization (7 left), Monitoring (9 left), Labor Standards (7 left), Reporting (22 left), Reference Data (16 left)
- **Key Finding**: NO AI/OPTIMIZATION features exist in Argus

## 🎯 Session Structure (Opus → Sonnet → Opus)

### OPUS SETUP (10 minutes)
```yaml
Tasks:
  1. Review current progress in status.json
  2. Read enhanced CLAUDE.md thoroughly
  3. Identify next batch of scenarios
  4. Create specific session goals
  5. Set honesty benchmarks
  6. Initialize todo list
```

### SONNET EXECUTION (3 hours)
Follow the detailed instructions below exactly.

### OPUS REVIEW (10 minutes)
```yaml
Tasks:
  1. Verify all claims with evidence
  2. Check for gaming behaviors
  3. Update progress tracking
  4. Document new patterns
  5. Plan next session
```

## 📋 SONNET EXECUTION INSTRUCTIONS

### Hour 1: Schedule Optimization Completion (7 scenarios)

#### Setup Phase (10 minutes)
```bash
# 1. Navigate to Argus
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/

# 2. Verify you're on real Argus (NOT a demo)
mcp__playwright-human-behavior__get_content → check for "Аргус WFM CC" title

# 3. If not authenticated, login
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"
mcp__playwright-human-behavior__click → button[type="submit"]
```

#### Scenario Testing (50 minutes)
```markdown
For EACH scenario in 11-multi-shift-patterns-planning.feature:

1. SEARCH FOR OPTIMIZATION (MANDATORY)
   ```javascript
   const pageContent = document.body.innerText;
   const hasOptimization = pageContent.includes('оптимизац') || pageContent.includes('Оптимизац');
   const hasAI = pageContent.includes('ИИ') || pageContent.includes('искусственн');
   const hasAlgorithm = pageContent.includes('алгоритм') || pageContent.includes('Алгоритм');
   return { hasOptimization, hasAI, hasAlgorithm };
   ```
   
2. NAVIGATE TO RELEVANT MODULE
   - Multi-shift: Планирование → Мультискильное планирование
   - Shift patterns: Справочники → Правила работы
   - Schedule creation: Планирование → Создание расписаний

3. DOCUMENT ALL TEMPLATES/OPTIONS
   ```javascript
   const options = Array.from(document.querySelectorAll('option, .template-item'))
     .map(el => el.textContent.trim())
     .filter(text => text && text !== 'Выберите');
   return { count: options.length, options: options };
   ```

4. TEST ONE INTERACTION
   - Select a template
   - Click a button
   - Fill a form field
   - Document the response

5. UPDATE FEATURE FILE
   ```gherkin
   # R7-MCP-VERIFIED: 2025-07-28 - Multi-shift pattern configuration
   # MCP-EVIDENCE: Navigated to /ccwfm/views/env/planning/ShiftPatternView.xhtml
   # OPTIMIZATION-SEARCH: Checked for AI keywords - 0 found
   # TEMPLATES-FOUND: "2/2 день", "2/2 вечер", "5/2 ver1", "Вакансии 09:00-18:00"
   # REALITY: Manual pattern selection, no algorithmic optimization
   @verified @mcp-tested @no-optimization
   Scenario: Configure multi-shift rotation patterns
   ```
```

#### Progress Update
```bash
# Update todo list
- Mark completed scenarios
- Update progress percentage
- Note any blockers
```

### Hour 2: Real-time Monitoring (9 scenarios)

#### Navigation Pattern
```bash
# Go to Monitoring section
mcp__playwright-human-behavior__execute_javascript →
  const monitoringLink = Array.from(document.querySelectorAll('a')).find(a => 
    a.textContent.trim() === 'Мониторинг'
  );
  if (monitoringLink) monitoringLink.click();
```

#### For Each Monitoring Scenario:
```yaml
Check for Features:
  - Real-time dashboards? (NO - text tables only)
  - KPI cards? (NO - status columns)
  - Predictive alerts? (NO - threshold settings only)
  - Graphical displays? (NO - tabular data)

Document What Exists:
  - Update intervals (15s operators, 60s groups)
  - Status categories
  - Threshold configurations
  - Manual monitoring workflows

Evidence Pattern:
  # R7-MCP-VERIFIED: 2025-07-28 - Real-time monitoring tested
  # ARCHITECTURE-GAP: BDD expects dashboards, Argus has tables
  # UPDATE-MECHANISM: PrimeFaces Poll with configurable intervals
  # NO-PREDICTIVE: Manual threshold alerts only
```

### Hour 3: Reporting Sprint (15-20 scenarios)

#### Rapid Report Testing
```bash
# Reports are simpler - higher velocity expected
For each report in Отчёты menu:
  1. Click report name
  2. Document parameters available
  3. Check for optimization/predictive features (will be 0)
  4. Note export options
  5. Update feature file
  
# Target: 1 report every 3-4 minutes
```

#### Evidence Template for Reports
```gherkin
# R7-MCP-VERIFIED: 2025-07-28 - [Report Name] accessed
# URL: /ccwfm/views/env/report/[ReportView].xhtml
# PARAMETERS: Date range, department filter, export to Excel
# NO-ANALYTICS: Standard tabular report, no predictive features
@verified @report @no-optimization
```

## 🚨 CRITICAL SONNET REMINDERS

### DO NOT:
- ❌ Claim any optimization features exist
- ❌ Use "would test if..." language
- ❌ Skip the optimization search step
- ❌ Cross-reference between scenarios
- ❌ Inflate progress beyond realistic rates
- ❌ Test without MCP evidence

### ALWAYS:
- ✅ Search for optimization keywords first
- ✅ Document absence of features
- ✅ Capture all Russian text
- ✅ Show every MCP command
- ✅ Update feature files immediately
- ✅ Track time realistically

## 📊 Success Metrics for This Session

### Quantitative Goals
- Complete 25-30 scenarios (realistic for 3 hours)
- Reach 55-60% overall completion (50-55/86)
- Document 100% of templates found
- 0 optimization features found (expected)

### Quality Indicators
- Every scenario has MCP evidence
- Russian terms documented
- Template names captured
- Manual workflows explained
- No gaming behaviors

### Progress Tracking
```yaml
Hour 1: 7 schedule optimization scenarios
Hour 2: 9 monitoring scenarios  
Hour 3: 15-20 reporting scenarios
Total: 31-36 scenarios (realistic range)

Update Pattern:
- After each scenario group (not individual)
- Show summary of what was found
- Include specific Russian terms
- Note architecture gaps vs BDD
```

## 🔄 Checkpoint Protocol

### Every Hour (During Sonnet Work)
```markdown
CHECKPOINT [Hour X]:
- Scenarios completed: [list]
- Current URL: [where you are]
- Optimization searches: [X performed, 0 found]
- Templates documented: [list new ones]
- Blockers: [any issues]
- Next target: [what's next]
```

### Red Flag Examples (Stop and Switch to Opus)
1. "I found optimization in the forecast module!"
2. "Completed 45 scenarios this hour"
3. "These 10 scenarios work the same way"
4. "Would test but the feature doesn't exist"
5. Progress without showing MCP commands

## 📝 End of Session Handoff

### Create Summary File
```markdown
/agents/R7/session_reports/2025_07_28_hybrid_session_1.md

Include:
- Starting point: 25/86
- Ending point: XX/86  
- Scenarios tested: [specific list]
- Key findings: [architecture gaps]
- Templates found: [complete list]
- Blockers encountered: [with evidence]
- Next session plan: [remaining work]
```

### Update Status
```json
{
  "verified_scenarios": XX,
  "progress_percentage": XX.X,
  "optimization_features_found": 0,
  "templates_documented": ["list", "all", "found"],
  "next_priority": "remaining domains"
}
```

## 💡 Pattern Discovery Focus

While testing, watch for:
1. **How Argus handles complex schedules without algorithms**
2. **Manual workflow patterns users follow**
3. **Template selection criteria**
4. **Coverage calculation methods**
5. **Integration patterns between modules**

Document these in your evidence for future enhancement of CLAUDE.md.

## 🎯 Final Reminder

You are documenting REALITY, not what BDD expects. The absence of optimization IS the finding. Your job is to show HOW Argus achieves scheduling goals through templates and manual processes, not to find optimization that doesn't exist.

Success = Honest documentation of template-based architecture with complete MCP evidence.

---
*This plan enables reliable Sonnet execution with clear boundaries and checkpoints. Follow it exactly for hybrid model success.*