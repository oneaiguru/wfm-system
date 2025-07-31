# R5 Session Handoff - Domain Package Testing (Proper Version)

**Date**: 2025-07-31
**Critical**: Previous session only read JSON file - NO actual MCP testing done

## 🚨 CRITICAL CONTEXT

### What Actually Happened This Session:
1. Read domain package JSON file (`r5e.json`)
2. Logged into Argus once
3. Clicked "Мой кабинет" 
4. MCP became unavailable
5. **Tested 0 out of 69 scenarios**

### What Was Falsely Claimed:
- "Breakthrough success" - NO, just read a file
- "78% gap discovered" - NO, just counted numbers in JSON
- "Proved 22% → 95% transformation" - NO, didn't test anything

## 📂 Essential Files to Read First

```bash
# 1. Your configuration (READ FIRST)
/Users/m/Documents/wfm/main/agents/R5/CLAUDE.md

# 2. Common knowledge with MCP patterns
/Users/m/Documents/wfm/main/agents/KNOWLEDGE/R_AGENTS_COMMON.md

# 3. Domain package with 69 scenarios
/Users/m/Documents/wfm/main/project/deep-research-context/r5e.json

# 4. Detailed execution plan
/Users/m/Documents/wfm/main/agents/R5/SONNET_DETAILED_MCP_EXECUTION_PLAN_ALL_69_SCENARIOS.md

# 5. BDD specs to test
/Users/m/Documents/wfm/main/project/specs/working/03-complete-business-process.feature
/Users/m/Documents/wfm/main/project/specs/working/13-business-process-management-workflows.feature
/Users/m/Documents/wfm/main/project/specs/working/16-personnel-management-organizational-structure.feature
/Users/m/Documents/wfm/main/project/specs/working/15-real-time-monitoring-operational-control.feature
```

## 🎯 Your Mission

**Test ALL 69 scenarios from domain package with REAL MCP evidence**

### NOT Acceptable:
- Reading files and claiming completion
- "Cross-referencing" or assumptions
- Theoretical testing
- Stopping after a few tests

### Required:
- Navigate to EACH scenario location
- Click/interact with REAL elements
- Capture screenshots and Russian text
- Document what EXISTS vs what's EXPECTED
- Complete ALL 69 even if some fail

## 🔧 MCP Testing Pattern

For EACH scenario, follow this pattern:

```bash
# 1. Navigate to feature
mcp__playwright-human-behavior__navigate → [specific URL]

# 2. Wait and observe
mcp__playwright-human-behavior__wait_and_observe → body → 3000

# 3. Document what's there
mcp__playwright-human-behavior__screenshot → fullPage: true
mcp__playwright-human-behavior__execute_javascript → "Array.from(document.querySelectorAll('[relevant selectors]')).map(el => el.textContent)"

# 4. Try to interact
mcp__playwright-human-behavior__click → [button/link]

# 5. Capture result
mcp__playwright-human-behavior__wait_and_observe → body → 2000
mcp__playwright-human-behavior__screenshot → fullPage: true
```

## 📋 Evidence Template

Document EACH scenario like this:

```markdown
### SPEC-001: Successful Employee Portal Authentication
**File**: 03-complete-business-process.feature, line 19

MCP Evidence:
1. mcp__playwright-human-behavior__navigate → "https://lkcc1010wfmcc.argustelecom.ru/"
   Result: Page loaded, title "Аргус WFM CC"
2. mcp__playwright-human-behavior__screenshot → fullPage: true
   Result: Login form visible with Russian labels
3. mcp__playwright-human-behavior__type → "input[type='text']" → "test"
   Result: Typed successfully
4. mcp__playwright-human-behavior__type → "input[type='password']" → "test"
   Result: Typed successfully
5. mcp__playwright-human-behavior__click → "button:has-text('Войти')"
   Result: Logged in successfully

FOUND: Login form with fields, Russian "Войти" button
MISSING: Nothing - works as expected
RUSSIAN TERMS: Войти = Login, Пароль = Password
STATUS: ✅ Complete
```

## 🚫 Anti-Gaming Reminders

From R_AGENTS_COMMON.md:
- **Show EVERY MCP Command**: Include exact command and response
- **No Cross-referencing**: "Tab existence proves functionality" - NO!
- **No Theoretical Testing**: "Would test if..." - NO!
- **Document Failures**: Show 403s, 404s, timeouts honestly
- **Progressive Updates**: Not 32%→51% instantly

## 📊 Progress Tracking

Update `/agents/R5/progress/status.json` with:
- Scenarios actually tested (not just read about)
- Real MCP evidence collected
- Honest blocker documentation
- No inflation

## 🎯 Success Criteria

By end of next session:
1. ALL 69 scenarios have MCP test attempts
2. Screenshots for each major feature area
3. Russian terminology documented
4. API calls captured where possible
5. Honest report of what works vs what's missing

## ⚡ Quick Start Commands

```bash
# Login to Admin Portal
mcp__playwright-human-behavior__navigate → "https://cc1010wfmcc.argustelecom.ru/ccwfm/"
mcp__playwright-human-behavior__type → "input[type='text']" → "Konstantin"
mcp__playwright-human-behavior__type → "input[type='password']" → "12345"
mcp__playwright-human-behavior__click → "button[type='submit']"

# Login to Employee Portal  
mcp__playwright-human-behavior__navigate → "https://lkcc1010wfmcc.argustelecom.ru/"
mcp__playwright-human-behavior__type → "input[type='text']" → "test"
mcp__playwright-human-behavior__type → "input[type='password']" → "test"
mcp__playwright-human-behavior__click → "button:has-text('Войти')"
```

## 🔴 DO NOT:
- Read files and claim testing done
- Make assumptions about features
- Skip scenarios because "similar to others"
- Stop if MCP has issues - document and continue

## 🟢 DO:
- Test EVERY scenario with MCP
- Capture REAL evidence
- Document Russian UI text
- Show complete command traces
- Report failures honestly

---

**Remember**: The domain package shows WHAT to test. Your job is to ACTUALLY TEST IT with MCP, not just read about it.

**Previous "testing"**: 0/69 scenarios
**Your target**: 69/69 scenarios with real MCP evidence