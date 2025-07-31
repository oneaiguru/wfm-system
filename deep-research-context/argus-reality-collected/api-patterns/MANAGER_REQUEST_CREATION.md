# Manager Request Creation - API Discovery Report

**Date**: 2025-07-29  
**Agent**: R5-ManagerOversight  
**Mission**: Find manager-side workaround for Vue.js employee request creation bug

## 🚨 Current Status: INVESTIGATION IN PROGRESS

### Problem Context
- R2 discovered Vue.js bug preventing employee request creation
- Employee portal field "Причина" clears itself, blocking form submission
- Need to test if managers can create requests FOR employees via JSF admin portal

### API Monitoring Setup ✅
- Universal API Monitor injected successfully
- Monitoring both XMLHttpRequest (JSF) and Fetch (REST) calls
- Ready to capture JSF ViewState patterns

## 🔍 Areas Explored

### 1. Employee Management (Сотрудники)
- **URL**: `/ccwfm/views/env/personnel/WorkerListView.xhtml`
- **Employee List**: Found "test t." user in system (513 total employees)
- **Interaction**: Clicked on test user row - no obvious request creation dialog
- **Assessment**: Direct employee-to-request creation not immediately visible

### 2. Personal Cabinet (Мой кабинет) 
- **URL**: `/ccwfm/views/env/personnel/PersonalAreaIncomingView.xhtml`
- **Calendar Present**: Full calendar interface with date picker
- **Buttons Found**: Several "Добавить" (Add) buttons detected
- **Calendar Interaction**: Right-clicked dates, found 119 calendar cells
- **Issue**: Context menus/dialogs not triggering properly

### 3. Requests Section (Заявки)
- **URL**: `/ccwfm/views/env/personnel/request/UserRequestView.xhtml`
- **Tabs**: "Мои" (My) and "Доступные" (Available) 
- **Current State**: Both tabs show "Нет данных" (empty)
- **Create Buttons**: No obvious "Create Request" buttons found

## 🧐 Technical Observations

### JSF Framework Patterns
- All admin URLs follow `/ccwfm/views/env/` pattern
- JSF ViewState management active (ready to capture)
- PrimeFaces AJAX components present
- Hidden dialogs detected but not triggering

### API Monitoring Ready
```javascript
// Monitor is active and will capture:
window.AGENT_API_LOG - Fetch API calls
window.AGENT_XHR_LOG - XMLHttpRequest calls
window.getAPIReport() - Generate summary
```

## 🔄 Next Investigation Steps

### A. Deep Calendar Exploration  
- Try double-clicking calendar dates
- Look for keyboard shortcuts (Ctrl+N, etc.)
- Examine calendar right-click context menu more carefully
- Check if specific date/time selection triggers forms

### B. Menu System Deep Dive
- Expand all admin menu sections systematically  
- Look for "Personnel Actions" or "Request Management"
- Check if there's an "Act on Behalf" or "Impersonate" feature
- Examine sub-menus under Персонал section

### C. Alternative Entry Points
- Check if Reports section has request creation
- Look in Planning/Scheduling sections
- Examine if Exchange (Биржа) has request creation features
- Test if Business Rules section allows request workflows

### D. Direct URL Testing
- Try URLs like `/PersonalAreaRequestCreateView.xhtml`
- Test different request type URLs
- Look for patterns in existing URLs to guess creation endpoints

## 🤔 Hypotheses to Test

### Theory 1: Calendar Context Menu
Manager request creation might be triggered by:
- Right-click on specific employee calendar dates
- Double-click on calendar cells
- Special keyboard combinations

### Theory 2: Hidden Admin Features
Request creation might be in:
- Advanced admin sections not yet explored
- Role-based menus that appear based on permissions
- Workflow management sections

### Theory 3: Different Architecture
Manager request creation might:
- Use completely different workflow than employee portal
- Be integrated into scheduling/planning tools
- Require different user permissions/roles

## 🚨 Blocker Status

**Current Blocker**: Cannot locate manager-side request creation interface

**Impact**: 
- Cannot test JSF request creation workflow
- Cannot compare to Vue.js employee portal approach
- Cannot provide workaround for R2's Vue.js bug

**Needs**: 
- Systematic exploration of remaining admin sections
- Possible coordination with other agents familiar with request workflows
- Alternative approach if manager creation doesn't exist

## 📋 API Capture Readiness

Once request creation workflow is found, will capture:
1. **Form Loading APIs**: Initial page/dialog load
2. **Employee Selection**: How managers specify target employee
3. **Request Type APIs**: Vacation/sick leave/exchange options
4. **Validation APIs**: Server-side validation vs client-side
5. **Submission APIs**: Complete JSF ViewState submission flow
6. **Notification APIs**: How employee gets notified of manager-created request

**Expected JSF Pattern**:
```javascript
POST /ccwfm/views/env/[section]/RequestCreateView.xhtml
javax.faces.partial.ajax=true
javax.faces.source=create_request_form-submit_button  
javax.faces.ViewState=[token]
employee_id=test
request_type=vacation
date_start=2025-07-30
// etc.
```

---

**Status**: Investigation continuing - will update when request creation workflow located