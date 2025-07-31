# R2-EmployeeSelfService MCP Unavailability Contingency Plan

**Purpose**: Productive work when MCP browser automation tools are not available  
**R2-Specific**: Employee portal analysis and request form resolution planning  
**Reference**: @../R1/MCP_UNAVAILABILITY_CONTINGENCY.md for general patterns

## 🎯 WHEN MCP TOOLS ARE UNAVAILABLE

### Immediate Assessment (5 minutes)
1. **Check tool availability**: Try `mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/`
2. **Document downtime**: Note exact time tools became unavailable
3. **Switch to R2 contingency mode**: Follow R2-specific plan below

## 📋 R2-SPECIFIC PRODUCTIVE CONTINGENCY ACTIVITIES

### 1. REQUEST FORM DEBUGGING ANALYSIS (60-90 minutes)

#### Form Validation Investigation
- **Review**: Current handoff documents for exact validation errors
- **Analyze**: All known field IDs (#input-181, #input-198, #input-245)
- **Plan**: Alternative date formats (DD.MM.YYYY, DD/MM/YYYY, YYYY-MM-DD)
- **Document**: JavaScript form analysis strategies

#### Dual-Portal Strategy Refinement
- **Compare**: Employee portal (Vue.js) vs admin portal (PrimeFaces) approaches
- **Plan**: Systematic user comparison testing (test/test vs Konstantin/12345)
- **Document**: Alternative credential testing approach (pupkin_vo/Balkhash22)

### 2. EMPLOYEE PORTAL ARCHITECTURE ANALYSIS (45-60 minutes)

#### Vue.js vs PrimeFaces Documentation
- **Framework Differences**: SPA routing vs traditional pages
- **Session Management**: Employee portal persistence vs admin timeouts
- **Component Patterns**: v-text-field vs traditional form inputs
- **Error Handling**: SPA 404s vs traditional error pages

#### Permission Matrix Development
```markdown
# R2 User Permission Matrix Template

| Feature | test/test (Employee) | Konstantin/12345 (Admin) | Expected Resolution |
|---------|---------------------|---------------------------|-------------------|
| Request Creation | BLOCKED (validation) | Test needed | Admin portal success? |
| Profile Access | 404 Not Found | May exist as user mgmt | Admin employee mgmt |
| Exchange Creation | No interface | Test needed | Admin function only? |
| Notification Access | Working (106+ items) | Test needed | Both portals |
```

### 3. SCENARIO PLAN REFINEMENT (60-75 minutes)

#### Update R2_COMPLETE_57_SCENARIOS_DETAILED_PLAN.md
- **Refine MCP sequences**: Add dual-portal comparison commands
- **Add error handling**: What to do when forms fail validation
- **Update timing estimates**: Based on dual-portal testing needs
- **Dependencies**: Document which scenarios depend on form resolution

#### Request Form Resolution Priority Matrix
```markdown
# Form Resolution Testing Priority

1. **CRITICAL PATH (2-3 hours)**:
   - Admin portal employee request testing
   - Alternative user credential testing
   - Date format systematic testing

2. **INVESTIGATION (1-2 hours)**:
   - JavaScript hidden field analysis
   - Network monitoring during submission
   - Backend API comparison

3. **FALLBACK (30 minutes)**:
   - Document as architectural limitation
   - Mark dependent scenarios as user-permission-blocked
```

### 4. EVIDENCE ORGANIZATION & QUALITY REVIEW (30-45 minutes)

#### Review Previous Evidence
- **Screenshots**: Organize evidence/screenshots/ with validation errors
- **Content extracts**: Clean up Russian UI text from Vue.js components  
- **Russian terms**: Update R2_EMPLOYEE_PORTAL_GLOSSARY.md with missed terms
- **Live data examples**: Compile notification timestamps, acknowledgment data

#### Evidence Gap Analysis
- **Missing evidence**: Which scenarios lack complete MCP sequences?
- **Quality improvements**: How to strengthen dual-portal evidence?
- **Pattern documentation**: Vue.js behavioral patterns to capture

### 5. HANDOFF TEMPLATE OPTIMIZATION (30-45 minutes)

#### Improve R2 Session Handoff Templates
- **Form resolution tracking**: Clear status indicators for validation blocker
- **User comparison results**: Template for dual-portal testing results
- **Architecture discoveries**: Vue.js vs PrimeFaces findings format
- **Next session preparation**: Specific debugging steps ready-to-execute

### 6. META-R SUBMISSION PREPARATION (45-60 minutes)

#### Current Status Analysis
- **Honest assessment**: 34/57 scenarios (59.6%) with evidence
- **Critical blocker impact**: Request form affects 8+ additional scenarios
- **Architectural limitations**: Profile 404, exchange creation missing
- **Success stories**: Theme system, notifications, acknowledgments working

#### Submission Quality Improvement
- **Evidence standards**: Ensure all claims have complete MCP sequences
- **Dual-portal context**: Include permission comparison where relevant
- **Russian terminology**: Complete Vue.js interface documentation
- **Live data proof**: Operational system evidence vs demo data

## 🔄 R2-SPECIFIC CONTINGENCY WORKFLOW

### Hour 1: Form Resolution Analysis
- Review all form validation evidence
- Plan systematic debugging approach
- Document dual-portal testing strategy
- Update user permission matrix

### Hour 2: Architecture Documentation
- Vue.js vs PrimeFaces behavioral differences
- Employee portal vs admin portal capabilities
- Session management and routing patterns
- Component structure documentation

### Hour 3: Scenario Plan Updates
- Refine MCP command sequences
- Add dual-portal comparison steps
- Update timing estimates for user switching
- Document dependency chains

## 📊 PRODUCTIVITY METRICS DURING DOWNTIME

### Documentation Improvements Completed
- [ ] Request form debugging strategy refined
- [ ] Dual-portal testing plan detailed
- [ ] User permission matrix updated
- [ ] Evidence gaps identified and planned
- [ ] Scenario plans optimized for form resolution
- [ ] Russian terminology updated

### Expected MCP Session Efficiency Gains
- **Faster startup**: Clear dual-portal testing sequence ready
- **Focused testing**: Specific form resolution approaches planned
- **Better evidence**: Improved dual-portal comparison templates
- **Quality submissions**: Higher evidence standards prepared

## 🎯 RESUME TESTING CHECKLIST

When MCP tools become available again:

1. **Immediate Priority**: Test admin portal request creation
   ```bash
   mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
   # Use R1 login sequence
   # Navigate to employee request management
   ```

2. **Secondary Priority**: Alternative employee credentials
   ```bash
   mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/
   # Test with pupkin_vo/Balkhash22
   ```

3. **Form Analysis**: JavaScript field discovery
   ```bash
   # Systematic form field analysis prepared during downtime
   ```

**Ready to resume with enhanced dual-portal testing strategy and form resolution focus!**