# Vacation Request Flow Analysis - BDD Spec vs Our Implementation

## BDD Spec Analysis (02-employee-requests.feature)

### Lines 12-24: Create Request for Time Off/Sick Leave
The spec describes:
- Navigation: "Календарь" (Calendar) tab
- Action: Click "Создать" (Create) button
- Request types in Russian:
  - больничный (sick leave)
  - отгул (time off)
  - внеочередной отпуск (unscheduled vacation)
- Submit to "Заявки" (Requests) page

### Our Implementation Analysis

#### RequestForm Component
**Current Implementation:**
- ✅ Form with request type selection
- ✅ Date range picker (start/end dates)
- ✅ Form submission to API
- ✅ Success message and redirect

**Request Types Mismatch:**
- Our types: vacation, sick, personal, training
- Spec types: больничный, отгул, внеочередной отпуск
- ❌ No Russian translations for request types
- ❌ Different categorization (we have "training", spec doesn't)

**Navigation Mismatch:**
- Spec: Calendar tab → Create button
- Our: Direct navigation to /requests
- ❌ No calendar integration for request creation

**Integration Gaps (from VACATION_JOURNEY_COMPLETE.md):**
- ✅ Fixed: Added name="type" to select (line 118)
- ❌ Still missing: name="reason" on textarea
- ❌ Route issue: /requests vs /requests/new

## Spec Updates Needed

### 1. Update Request Types (Lines 16-20)
```gherkin
# UPDATED: 2025-07-25 - Align with implementation
Scenario: Create Request for Time Off/Sick Leave/Unscheduled Vacation
  Given I am logged into the system as an employee
  When I navigate to the "Time Off" link
  And I select request type from:
    | Request Type | Russian Translation |
    | vacation | отпуск |
    | sick | больничный |
    | personal | отгул |
    | training | обучение |
  And I fill in start date and end date
  And I provide a reason
  And I submit the request
  Then the request should be created with status "Pending"
  And I should see success message "Request submitted successfully"
  And I should be redirected to "/requests/history"
```

### 2. Remove Calendar-Based Creation
The implementation doesn't use calendar for request creation, it's a direct form approach.

### 3. Add Missing Scenarios
```gherkin
# NEW: 2025-07-25 - Date validation
Scenario: Validate request dates
  Given I am creating a vacation request
  When I select end date before start date
  Then I should see validation error
  And the form should not submit

# NEW: 2025-07-25 - Reason requirement
Scenario: Require reason for requests
  Given I am creating a request
  When I submit without entering a reason
  Then I should see "Reason is required" error
```

## Integration Patterns Applied

### Pattern 2: Form Field Accessibility
Current status:
- ✅ name="type" on select (fixed)
- ✅ name="startDate" on start date input
- ✅ name="endDate" on end date input
- ❌ Still need name="reason" on textarea

### Pattern 1: Route Granularity
- Current: /requests
- Tests expect: /requests/new
- Need to add route or update tests

## Recommendations

1. **Add Russian Translations**: Create translation map for request types
2. **Fix Textarea Name**: Add name="reason" to textarea field
3. **Align Routes**: Either add /requests/new route or update e2e tests
4. **Remove Calendar Dependency**: Update spec to reflect direct form approach
5. **Add Validation**: Implement date and reason validation per spec

## Shift Exchange Analysis (Lines 27-37)

**Current State**: ❌ Not implemented
- No shift selection UI
- No three-dot menu in shifts
- No exchange request type

This is a significant gap that would require:
- Calendar/schedule view implementation
- Shift selection capability
- Exchange request workflow

## Files to Update

1. `/project/specs/working/02-employee-requests.feature`
   - Add: `# VERIFIED: Basic request creation works`
   - Add: `# UPDATED: Request types aligned with implementation`
   - Add: `# TODO: Shift exchange not implemented`

2. `/project/src/ui/src/components/RequestForm.tsx`
   - Line ~178: Add name="reason" to textarea
   - Consider adding Russian translations

3. `/project/src/ui/src/App.tsx`
   - Add route: `<Route path="/requests/new" element={<RequestForm />} />`