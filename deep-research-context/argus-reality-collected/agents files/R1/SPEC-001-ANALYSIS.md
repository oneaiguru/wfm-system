# SPEC-001: System roles configuration - Verification Analysis

**Scenario**: SPEC-001  
**Agent**: R1 (R-AdminSecurity)  
**File**: `26-roles-access-control.feature`  
**Status**: Ready for verification  
**Demo Value**: 3  

## 🎯 Scenario Overview

**Purpose**: Verify system roles configuration functionality in Argus vs our implementation  
**Domain**: Admin & Security (foundational for all other agents)  
**Priority**: HIGH - Required for other domain testing  

## 📋 Expected Verification Steps

### 1. Navigation Verification
```gherkin
Given I am logged in as an administrator
When I navigate to roles management
Then I should see the roles configuration interface
```

**MCP Commands to Execute**:
```javascript
// Navigate to admin login
await mcp__playwright__browser_navigate({
  url: "https://cc1010wfmcc.argustelecom.ru/ccwfm/"
});

// Login as admin
await mcp__playwright__browser_type({
  element: "Username field",
  ref: "input[name='username']",
  text: "Konstantin"
});

await mcp__playwright__browser_type({
  element: "Password field", 
  ref: "input[name='password']",
  text: "12345"
});

await mcp__playwright__browser_click({
  element: "Login button",
  ref: "button[type='submit']"
});

// Navigate to roles
await mcp__playwright__browser_navigate({
  url: "https://cc1010wfmcc.argustelecom.ru/ccwfm/roles"
});
```

### 2. System Roles Verification
Check for standard WFM roles:
- **Administrator**: Full system access
- **Manager**: Team oversight, approvals  
- **Employee**: Self-service functions
- **HR**: Personnel management
- **Scheduler**: Schedule management

### 3. Role Configuration Interface
Verify presence of:
- Role creation/editing forms
- Permission assignment interface
- Role hierarchy display
- User assignment to roles
- Audit trail for role changes

## 🔍 Reality vs Specification Analysis

### Expected Argus Behavior:
1. Roles accessible via admin interface
2. Clear role management UI
3. Permission granularity controls
4. User-role assignment capability

### Our Implementation Check:
- Component: `RolesSettings.tsx`
- API: `/api/v1/roles/*`
- Database: `roles`, `user_roles`, `permissions` tables

## 📊 Verification Checklist

- [ ] Admin login successful
- [ ] Roles management accessible
- [ ] System roles present and correct
- [ ] Role creation interface functional
- [ ] Permission assignment working
- [ ] User-role assignment operational
- [ ] Role hierarchy properly displayed
- [ ] Audit logging for changes

## 🚨 Known Patterns to Watch For

From integration patterns library:
- **Pattern 4**: Admin route separation (expect `/admin/roles` vs `/roles`)
- **Route granularity mismatch**: Tests expect specific routes
- **Form field accessibility**: Missing `name` attributes for automation
- **Test ID missing**: Components lack `data-testid` attributes

## ✅ Success Criteria

**100% Parity**: All role management functions work identically  
**90% Parity**: Minor UI differences, core functionality identical  
**70% Parity**: Some features missing but basic roles work  
**<70% Parity**: Significant gaps requiring development work

## 📝 Verification Template

```gherkin
# VERIFIED: 2025-07-26 - [What was checked via MCP navigation]
# REALITY: [Actual behavior observed]
# PARITY: X% - [Calculation: working features / total features]
# TODO: [Specific gaps if parity < 100%]
# PATTERN: [If matches Pattern 1-6 or new pattern discovered]
@verified @admin @roles
Scenario: System roles configuration
  Given I am logged in as administrator
  When I access roles management
  Then system roles are properly configured
  And role permissions can be managed
  And users can be assigned to roles
```

## 🔄 Next Steps

1. **Execute MCP verification** when browser access restored
2. **Document reality match percentage**
3. **Tag scenario as @verified** 
4. **Create test users** for other R-agents
5. **Update BDD registry** with results

**Status**: Ready for execution - awaiting browser access resolution