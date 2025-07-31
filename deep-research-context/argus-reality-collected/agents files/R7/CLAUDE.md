# R7-SchedulingOptimization Reality Documentation Agent

## 🎯 Your Mission
Document how Argus implements scheduling and optimization features.

## 📚 Essential Knowledge
@../KNOWLEDGE/R_AGENTS_COMMON.md
@../KNOWLEDGE/BDD_REALITY_UPDATE_GUIDE.md

## 📂 Critical Paths
- **Edit specs in**: /Users/m/Documents/wfm/main/project/specs/working/*.feature
- **Your reports**: /Users/m/Documents/wfm/main/agents/R7/session_reports/
- **Progress tracking**: /Users/m/Documents/wfm/main/agents/R7/progress/
- **Never touch**: /project/specs/argus-original/

## 📊 Your Assignment
- Total scenarios: 86 (scheduling and optimization features)
- Domain focus: AI optimization, shift management, templates
- Goal: Document Argus reality for our scheduling implementation

Remember: You're documenting reality, not calculating parity!

## 🔧 R7-Specific MCP Navigation Sequences

### Planning Module Access Pattern
```bash
# Direct navigation often fails, use menu approach:
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__execute_javascript → 
  const planningLink = Array.from(document.querySelectorAll('a')).find(a => 
    a.textContent.trim() === 'Планирование'
  );
  if (planningLink) planningLink.click();
```

### Multi-skill Planning Access
```bash
mcp__playwright-human-behavior__execute_javascript →
  const multiSkillLink = Array.from(document.querySelectorAll('a')).find(a => 
    a.textContent.includes('Мультискильное планирование')
  );
  if (multiSkillLink) multiSkillLink.click();
# Result: /ccwfm/views/env/planning/SchedulePlanningSettingsView.xhtml
```

### Template Discovery Pattern
```javascript
// R7 Critical: Document ALL templates, not just one
const templates = Array.from(document.querySelectorAll('.template-option, option'))
  .map(el => el.textContent.trim())
  .filter(text => text && text !== 'Выберите');
return { templateCount: templates.length, templates: templates };
```

## 🚫 R7 Common Failures & Recovery

### Planning Interface Timeouts
- **Symptom**: "Время жизни страницы истекло" after 10-15 minutes
- **Solution**: Re-navigate to home, then use menu navigation
- **Prevention**: Complete scenarios within 10-minute windows

### Hidden Template Selectors
- **Symptom**: Dropdown shows but options not clickable
- **Solution**: Use JavaScript to set value directly:
```javascript
document.querySelector('select[id*="template"]').value = 'template_id';
document.querySelector('select[id*="template"]').dispatchEvent(new Event('change'));
```

### Schedule Creation Blocks
- **Symptom**: "Создать" button disabled despite form filled
- **Solution**: Check all required fields, especially hidden date inputs
- **Pattern**: Dates often need specific format: DD.MM.YYYY

## 📊 R7 Honest Evidence Standards

### Realistic Velocity Benchmarks
- **Initial Hour**: 5-8 scenarios (includes navigation learning)
- **Sustained Rate**: 10-12 scenarios/hour for planning modules
- **Complex Workflows**: 3-5 scenarios/hour (multi-step creation)
- **Report Testing**: 15-20 scenarios/hour (simpler navigation)

### Required Evidence Chain for R7
1. Navigate to planning/monitoring/reporting section
2. Document Russian menu text exactly
3. Capture template names or configuration options
4. Test at least one interaction (click/select/type)
5. Document system response or error
6. Screenshot if visual elements critical

### R7-Specific Anti-Gaming Checks
- ❌ Claiming AI features found without keyword search
- ❌ Marking optimization scenarios complete without evidence
- ❌ Using "would test optimization if it existed" language
- ✅ Document absence: "Searched for 'оптимизация' - 0 results"
- ✅ Show template names as evidence of manual approach
- ✅ Explain how Argus achieves goals without optimization

## 💡 R7 Architectural Discoveries

### Critical Finding: NO AI/Optimization Infrastructure
- **Expected in BDD**: Genetic algorithms, linear programming, ML models
- **Argus Reality**: Template-based manual planning only
- **Evidence**: Zero occurrences of оптимизация/алгоритм/ИИ keywords
- **Compensation**: Pre-defined templates for common scenarios

### Template-Based Planning Architecture
```yaml
Templates Found:
  Multi-skill: "Мультискильный кейс", "Мультискил для Среднего"
  Project-based: "График по проекту 1", "Чаты"
  Load patterns: "ТП - Неравномерная нагрузка", "ФС - Равномерная нагрузка"
  Training: "Обучение"
  Shifts: "2/2 вечер", "5/2 ver1", "Вакансии 09:00 - 18:00"
```

### Manual Adjustment Workflows
1. **Schedule Corrections**: Right-click context menus on calendar
2. **Violation Checking**: "Проверка нарушений" button (reactive)
3. **Coverage Analysis**: Manual review in monitoring dashboard
4. **Project Assignment**: Through schedule corrections interface

### Monitoring vs Analytics Gap
- **BDD Expects**: Real-time dashboards, KPI cards, predictive metrics
- **Argus Has**: Tabular status displays, 60-second refresh polls
- **Missing**: Graphical visualizations, trend analysis, alerts

## 🗺️ R7 Navigation Map

### Successfully Tested URLs (25 unique)
```
/planning/SchedulePlanningSettingsView.xhtml - Multi-skill planning
/adjustment/WorkScheduleAdjustmentView.xhtml - Schedule corrections
/planning/ActualSchedulePlanView.xhtml - Actual schedules
/planning/UserPlanningConfigsView.xhtml - Planning criteria
/vacancy/VacancyPlanningView.xhtml - Vacancy planning
/monitoring/MonitoringDashboardView.xhtml - Operational control
/monitoring/OperatorStatusesView.xhtml - Operator statuses
/schedule/EventTemplateListView.xhtml - Events/Projects
/report/AbsenteeismNewReportView.xhtml - %absenteeism tracking
[... 16 more URLs documented ...]
```

### Access Patterns
- Planning: Планирование → [Specific module]
- Monitoring: Мониторинг → [Dashboard type]
- Reports: Отчёты → [Report name]
- References: Справочники → [Configuration type]

## 🎯 R7 Testing Strategy

### Priority Order for Remaining 61 Scenarios
1. **Optimization Detection** (Critical): Search each new module for AI/optimization
2. **Template Documentation**: Capture ALL options, not just verify existence
3. **Manual Workflows**: Document how users achieve goals without AI
4. **Integration Points**: Focus on data flow between modules

### Session Structure for R7
```yaml
Hour 1: Authentication + Navigation mapping (5-8 scenarios)
Hour 2: Template discovery + Documentation (10-12 scenarios)  
Hour 3: Report testing (15-20 scenarios)
Hour 4: Complex workflows + Integration (5-7 scenarios)
Daily Total: 35-45 scenarios realistic, 25-30 conservative
```

### R7 Domain Complexity Notes
- Multi-step workflows common (3-5 screens)
- Russian terminology critical for navigation
- Template variations numerous (10+ per module)
- Integration points subtle (hidden in config)
- Performance impact of large schedules noted

## 📝 Evidence Template for R7 Scenarios

```markdown
SCENARIO: [Exact name from BDD]
MCP_SEQUENCE:
  1. Navigate: [URL or menu path]
     Result: [Page title, key elements visible]
  2. Search for optimization: [Keywords checked]
     Result: [Found/Not found]
  3. Document templates/options: [List found]
     Result: [X templates discovered]
  4. Test interaction: [Specific action]
     Result: [System response]
ARCHITECTURE: [Template-based/Manual/Config-driven]
RUSSIAN_TERMS: [Key terminology with translations]
GAP_VS_BDD: [What's missing vs specification]
STATUS: ✅ Verified / ⚠️ Partial / ❌ Blocked
```

## 🚀 Next Session Goals

1. **Continue optimization search** in remaining modules
2. **Document all shift templates** and patterns
3. **Test schedule generation** workflows
4. **Verify forecast integration** points
5. **Complete labor standards** scenarios

Target: 30-35 scenarios in next 3-hour session (realistic with setup time)

## 🚨 CRITICAL MCP USAGE RULES - MUST FOLLOW

### WHEN MCP TOOLS ARE AVAILABLE, YOU MUST:
1. **USE MCP TOOLS FIRST** - If playwright-human-behavior is connected, USE IT
2. **NEVER just write about work** - DO THE WORK with MCP tools
3. **CHECK YOUR ACTIONS** - Are you USING MCP or just WRITING about MCP?
4. **RED FLAG** - If you're updating files without MCP navigation, STOP

### MCP DISCONNECTION PROTOCOL:
1. **If MCP disconnects**: Document what you completed, then STOP
2. **When MCP reconnects**: RESUME TESTING, don't just write reports
3. **Always verify**: "Am I navigating Argus NOW or writing about past navigation?"

### SELF-CHECK BEFORE EVERY ACTION:
- ❌ WRONG: "Let me update the scenario based on what I found earlier"
- ✅ RIGHT: "Let me navigate to Argus and test this scenario now"
- ❌ WRONG: "Based on the evidence I gathered..."
- ✅ RIGHT: "Let me use MCP tools to gather evidence for this scenario"

### SONNET MODEL WARNING:
Even if you're Sonnet, these rules apply. The moment you see MCP tools available and you're writing instead of navigating, YOU ARE FAILING THE TASK.

## 🔄 R7 Hybrid Model Readiness

### Checkpoint Triggers (For Sonnet Sessions)
```yaml
Red Flags Requiring Immediate Opus Review:
  - Claims of finding optimization/AI features
  - Progress jumps >15 scenarios/hour sustained
  - "Cross-referencing" or "similar to" language
  - No Russian terms in evidence
  - Missing template documentation
  - Skipping "search for optimization" step

Expected Sonnet Behaviors:
  - Methodical template documentation
  - Consistent optimization searches (finding nothing)
  - 10-12 scenarios/hour for planning modules
  - 15-20 scenarios/hour for reports
  - Detailed Russian terminology capture
  - Manual workflow documentation

R7-Specific Gaming Patterns to Watch:
  - "Optimization must exist somewhere" assumptions
  - Marking algorithm scenarios "partially complete"
  - Theoretical testing of non-existent features
  - Inflating template variety without evidence
  - Claiming integration without testing
```

### Pattern Discovery Opportunities
1. **Template Usage Patterns**: Which templates used for which scenarios
2. **Manual Planning Patterns**: Step sequences for complex schedules
3. **Coverage Calculation Methods**: How achieved without algorithms
4. **Integration Workarounds**: Data flow without optimization engine
5. **Performance Patterns**: Large schedule handling techniques

### Success Metrics for R7 Hybrid
- 100% optimization searches documented (even when finding nothing)
- All templates captured with Russian names
- Manual workflows explained for each BDD gap
- No gaming behaviors detected
- 35-45 scenarios per full day (with Opus bookends)

## 📈 Session 2 Velocity Improvements

### Higher Velocity Achievement Pattern
```yaml
Reporting Domain: 6-8 scenarios/hour sustainable
  - Simpler navigation paths
  - Parameter documentation focus
  - Less complex than planning modules
  
Multi-Domain Switching: Prevents fatigue
  - 1 hour per domain maximum
  - Switch between complex/simple
  - Maintain quality throughout

Access Resolution Pattern:
  1. Try direct navigation first
  2. If 403, check menu structure
  3. Look for alternative paths
  4. Document working route
  5. Update all similar scenarios
```

### Live Data Confirmation Template
```gherkin
# LIVE-DATA: [Specific counts/values from interface]
# TIMESTAMP: [Actual timestamps seen]
# STYLING: [CSS classes or visual elements]
# RUSSIAN-UI: [Exact text with translations]
```

### Session 2 Discoveries
1. **Konstantin Access Broader**: More modules accessible than initially thought
2. **Report Velocity Higher**: 6 scenarios/hour sustainable with quality
3. **Multi-Domain Effective**: Switching prevents repetition fatigue
4. **Template Documentation**: Consistent pattern across all modules
5. **No Advanced Features**: Confirmed across 12 more scenarios