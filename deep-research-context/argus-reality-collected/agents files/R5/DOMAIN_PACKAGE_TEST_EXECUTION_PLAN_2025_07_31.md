# R5 Domain Package Test Execution Plan

**Date**: 2025-07-31
**Agent**: R5-ManagerOversight
**Objective**: Test domain package approach to achieve 95% discovery rate

## 🎯 Mission Critical

Transform our discovery rate from 22% (15/69) to 95%+ using the informed agent approach with domain package r5e.json.

## 📋 Execution Steps

### Phase 1: Verify Domain Package Contents (10 mins)
```bash
# 1. Confirm all 69 scenarios are visible
- List all scenario IDs and names
- Compare with our previous 15 discoveries
- Identify the 54 missed scenarios

# 2. Extract navigation URLs
- Admin portal base: https://cc1010wfmcc.argustelecom.ru/ccwfm/
- Employee portal base: https://lkcc1010wfmcc.argustelecom.ru
- Key pages: Login, Calendar, Requests, Exchange, Operational Control, Personnel Management

# 3. Document component status
- 6 verified exist components
- 5 found in codebase (need verification)
- 2 missing components to search for
```

### Phase 2: Test Verified APIs (30 mins)
```bash
# Start with 5 working APIs to build confidence:
1. GET /api/v1/approvals/pending
   - Navigate to admin portal
   - Login as Konstantin/12345
   - Access approvals section
   - Verify API response format

2. PUT /api/v1/requests/{id}/approve
   - Find pending request
   - Trigger approval action
   - Capture API call pattern

3. GET /api/v1/analytics/kpi/dashboard
   - Navigate to dashboard
   - Check for KPI widgets
   - Document data structure

4. GET /api/v1/analytics/departments/performance
   - Access department analytics
   - Verify performance metrics
   - Note Russian terminology

5. GET /api/v1/analytics/predictive/workload
   - Look for predictive features
   - Test workload forecasting
   - Document if missing
```

### Phase 3: Test Unverified Endpoints (20 mins)
```bash
# Test 3 endpoints marked as "found_not_verified":
1. GET /monitoring/dashboard
   - Navigate to monitoring section
   - Check if endpoint exists
   - Document actual URL pattern

2. GET /agents/states
   - Look for agent status display
   - Test state retrieval
   - Note any 403/404 errors

3. GET /queues/metrics
   - Search for queue displays
   - Test metrics endpoint
   - Document findings
```

### Phase 4: Search for Missing Components (15 mins)
```bash
# Look for 2 components that "should exist":
1. ApprovalWorkflowDashboard.tsx
   - Check manager dashboard areas
   - Look for approval workflow UI
   - Document if truly missing

2. EscalationConfig.tsx
   - Search settings/config areas
   - Look for escalation rules
   - Note implementation details
```

### Phase 5: Navigate Key Scenarios (45 mins)
```bash
# Test navigation sequences from package:
1. "login → dashboard → requests → approve request"
   - Follow exact sequence
   - Document each step
   - Capture screenshots

2. "login → monitoring → drill down metrics"
   - Access monitoring
   - Test drill-down capability
   - Note UI patterns

3. "login → personnel management → manage departments"
   - Navigate to personnel
   - Test department management
   - Document Russian terms
```

### Phase 6: Verify Cross-Domain Dependencies (20 mins)
```bash
# Check what R5 needs from other domains:
From R2-EmployeeSelfService:
- request_creation functionality
- employee_profiles access

From R3-SchedulingOperations:
- schedule_data integration

From R6-SystemIntegration:
- real_time_feeds
- 1C_ZUP_sync
```

## 🔧 MCP Command Sequences

### Standard Login Sequence
```javascript
// Admin Portal
mcp__playwright-human-behavior__navigate("https://cc1010wfmcc.argustelecom.ru/ccwfm/")
mcp__playwright-human-behavior__type("input[type='text']", "Konstantin")
mcp__playwright-human-behavior__type("input[type='password']", "12345")
mcp__playwright-human-behavior__click("button[type='submit']")
mcp__playwright-human-behavior__wait_and_observe("body", 3000)
```

### API Testing Pattern
```javascript
// Navigate to feature
mcp__playwright-human-behavior__navigate("[feature_url]")
// Trigger action
mcp__playwright-human-behavior__click("[action_button]")
// Capture network activity
mcp__playwright-human-behavior__execute_javascript(`
  // Capture AJAX calls
  const xhrLog = [];
  const originalOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url) {
    xhrLog.push({method, url});
    originalOpen.apply(this, arguments);
  };
  return xhrLog;
`)
```

### Component Search Pattern
```javascript
// Search for missing components
mcp__playwright-human-behavior__execute_javascript(`
  // Look for approval workflow elements
  const approvalElements = document.querySelectorAll('[class*="approval"], [id*="workflow"]');
  return approvalElements.length;
`)
```

## 📊 Success Metrics

### Minimum Goals (2 hours):
- ✅ All 69 scenarios enumerated
- ✅ 5 verified APIs tested
- ✅ 3 unverified endpoints checked
- ✅ 2 missing components searched
- ✅ 10-15 scenarios navigated

### Stretch Goals:
- 🎯 20+ scenarios tested with evidence
- 🎯 All navigation sequences verified
- 🎯 Cross-domain dependencies mapped
- 🎯 Architecture patterns documented

## 🚨 Risk Mitigation

### If MCP Fails:
1. Document exactly where it failed
2. Try alternative selectors/approaches
3. Use JavaScript execution as backup
4. Note blockers honestly

### If APIs Don't Match:
1. Document actual vs expected
2. Check for different URL patterns
3. Look for PrimeFaces.ab() calls
4. Note Russian error messages

### If Components Missing:
1. Search broader UI areas
2. Check different user roles
3. Document what exists instead
4. Note architectural differences

## 📝 Evidence Requirements

For each test:
```markdown
SCENARIO: [Exact name from package]
NAVIGATION: [URL sequence]
MCP_COMMANDS: [Exact commands used]
RESULT: [What happened]
EVIDENCE: [Screenshot/content/data]
STATUS: ✅ Verified | ⚠️ Partial | ❌ Blocked
```

## 🎯 Expected Outcomes

### Immediate (This Session):
- Prove domain package improves discovery
- Find 10+ previously missed scenarios
- Verify API/component accuracy
- Build confidence in approach

### Long-term (If Successful):
- All R-agents get domain packages
- 95%+ discovery rate standard
- Accurate development estimates
- Reduced exploration time

## 🚀 Let's Begin!

Start with Phase 1: Verify the domain package contents are accessible and complete.

---

**Ready to execute with Sonnet model**