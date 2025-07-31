# Employee Request Management Analysis - Argus vs Our Implementation

## BDD Spec Reference
File: `/project/specs/working/02-employee-requests.feature`

## Our Current Implementation

### 1. Request Creation Flow (Lines 12-24 of BDD spec)

#### What We Have:
- **Location**: `/modules/employee-portal/components/requests/RequestForm.tsx`
- **Multi-step wizard**: 4 steps (Request Type → Dates → Reason → Review)
- **Request Types**:
  - ✅ Vacation (vacation) - "Annual paid time off"
  - ✅ Sick Leave (sick_leave) - "Medical leave of absence"
  - ✅ Time Off (time_off) - "Compensatory time or personal leave"
  - ✅ Shift Change (shift_change) - "Schedule modification request"
  - ✅ Overtime (overtime) - "Extra work hours request"

#### BDD Spec Mapping:
```
BDD Term (Russian) → Our Implementation (English)
больничный → sick_leave
отгул → time_off
внеочередной отпуск → vacation (we don't distinguish between regular/unscheduled)
```

#### ⚠️ Gaps Identified:
1. **Terminology**: We use English terms, spec uses Russian
2. **Navigation**: Spec expects "Календарь" tab, we have "Employee Portal → Requests"
3. **Create Button**: Spec expects "Создать", we have "➕ New Request"
4. **Unscheduled Vacation**: We don't differentiate between regular and unscheduled vacation

### 2. Shift Exchange Request (Lines 27-36)

#### What We Have:
- Basic shift change request type
- Select current shift and requested shift from dropdowns
- No direct integration with calendar view

#### ❌ Missing from Implementation:
1. **Calendar Integration**: Can't click on shift in calendar
2. **Three Dots Menu**: No contextual menu in shift window
3. **Exchange Mechanism**: We have "shift change" not "shift exchange"
4. **Other Employee Selection**: No way to specify whose shift you want

### 3. Accept Shift Exchange (Lines 39-47)

#### ❌ Not Implemented:
- No "Available" requests tab
- No mechanism to accept requests from other operators
- Request list exists but no exchange-specific functionality

### 4. Supervisor Approval with 1C ZUP Integration (Lines 48-66)

#### What We Have:
- Basic request submission to API
- Status tracking (draft, submitted)
- Employee selection dropdown

#### ❌ Missing Critical Integration:
1. **1C ZUP Integration**:
   - No `sendFactWorkTime` API calls
   - No automatic document generation
   - No time type mapping (NV, OT codes)
2. **Approval Workflow**:
   - No supervisor view implemented
   - No approval/rejection mechanism
   - No integration confirmation

### 5. Request Status Tracking (Lines 79-94)

#### What We Have:
- Basic status: draft, submitted
- Request list with filtering

#### ❌ Missing Status Flow:
- Expected: Создана → На рассмотрении → Одобрена/Отклонена
- Actual: draft → submitted (no further progression)

## Technical Implementation Details

### API Integration Status:
```typescript
// Current implementation (line 283-284):
const result: ApiResponse<SubmissionResult> = await realRequestService.submitVacationRequest(requestData);

// What's missing:
// - 1C ZUP integration endpoints
// - Supervisor approval endpoints
// - Status update webhooks
// - Document generation API
```

### Database Schema Requirements:
Based on the BDD spec, we need:
1. **requests** table with status progression
2. **shift_exchanges** table for operator-to-operator exchanges
3. **1c_integration_log** for tracking document creation
4. **approval_history** for supervisor actions

## Recommendations for BDD Spec Updates

### 1. Align Terminology
```gherkin
# UPDATED: 2025-07-25 - English/Russian terminology mapping
Scenario: Create Request for Time Off/Sick Leave/Unscheduled Vacation
  Given I am logged into the employee portal as an operator
  When I navigate to the "Employee Portal" section
  And I click the "New Request" button
  And I select request type from:
    | Request Type | Russian | English |
    | больничный | Sick Leave | sick_leave |
    | отгул | Time Off | time_off |
    | внеочередной отпуск | Unscheduled Vacation | vacation |
```

### 2. Add Missing Implementation Steps
```gherkin
# NEW: 2025-07-25 - Implementation reality
Scenario: Progressive Request Implementation
  Given we implement in phases
  When Phase 1: Basic request creation (DONE)
  Then Phase 2: Approval workflow (TODO)
  And Phase 3: 1C ZUP integration (TODO)
  And Phase 4: Shift exchange marketplace (TODO)
```

### 3. Document Current Limitations
```gherkin
# REALITY CHECK: 2025-07-25
Scenario: Current System Capabilities
  Given the current implementation
  Then can create vacation requests only
  And no 1C integration exists yet
  And approval workflow not implemented
  But foundation is ready for expansion
```

## Priority Implementation Roadmap

### Phase 1 (Complete) ✅:
- Basic request creation form
- Multi-step wizard
- Employee selection
- API submission

### Phase 2 (Next Priority) 🎯:
1. Implement supervisor dashboard
2. Add approval/rejection workflow
3. Status progression (Создана → На рассмотрении → Одобрена/Отклонена)
4. Email notifications

### Phase 3 (Integration):
1. 1C ZUP API integration
2. Document type mapping
3. Automatic time type creation
4. Integration confirmation

### Phase 4 (Advanced):
1. Shift exchange marketplace
2. Calendar integration
3. Mobile app support
4. Real-time notifications

## Argus Comparison Notes
Since we couldn't access Argus directly (403 Forbidden), this analysis is based on:
- BDD specifications
- Our current implementation
- Standard WFM patterns

The key insight: Our implementation follows modern SPA patterns while Argus likely uses traditional server-rendered pages with Russian UI. The business logic should remain equivalent despite UI differences.