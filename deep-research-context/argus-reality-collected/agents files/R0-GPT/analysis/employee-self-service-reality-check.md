# Employee Self-Service - Reality Check Analysis

## BDD Spec vs Actual Product vs Our Implementation

### Original BDD Spec (from documentation):
```gherkin
Scenario: Create Request for Time Off/Sick Leave
  Given I navigate to Calendar tab
  When I click Create button
  Then I select request type and submit
```

### What Argus ACTUALLY Has (from exploration):
```gherkin
Scenario: Employee Personal Cabinet - Complete Journey
  Given I am on the employee portal "https://lkcc1010wfmcc.argustelecom.ru/"
  
  # The REAL navigation structure
  When I access the personal cabinet
  Then I see these main sections (not theoretical ones):
    | Section | Russian | What's Actually There |
    | Calendar | Календарь | Month/week/day views with color-coded shifts |
    | Requests | Заявки | Tabs: Current, History, Available from others |
    | Profile | Профиль | Personal info, notifications, preferences |
  
  # The REAL request creation flow
  When I create a vacation request
  Then the actual process is:
    1. Go to Calendar (not a generic "requests" page)
    2. See my schedule with existing shifts
    3. Click specific dates I want off
    4. Right-click or use "Create Request" button
    5. Select from ONLY these types:
       - Отпуск (Vacation)
       - Больничный (Sick leave)  
       - Отгул (Time off)
    6. See automatic conflict checking
    7. Submit and get confirmation number
```

### What Our System Has:
```gherkin
Scenario: Our Current Implementation
  Given I navigate to http://localhost:3000/employee-portal
  
  # What we built
  Then I see:
    ✅ Employee Portal with sidebar navigation
    ✅ Dashboard with performance metrics
    ❌ No calendar integration
    ❌ No request creation
    ❌ Generic menu items not matching Argus
```

## Priority Gaps to Fix

### HIGH PRIORITY (Demo Critical):
1. **Calendar Integration**
   - Argus: Full calendar with shifts visible
   - Ours: Just a "My Schedule" link
   - Fix: Add actual calendar component

2. **Request Creation Flow**  
   - Argus: Context-aware from calendar
   - Ours: No request form at all
   - Fix: Add RequestForm.tsx connected to dates

3. **Request Types**
   - Argus: Only 3 specific types
   - Our BDD: Lists many theoretical types
   - Fix: Simplify to match reality

### MEDIUM PRIORITY:
1. **Visual Schedule Display**
   - Argus: Color-coded shifts, breaks visible
   - Ours: Text list
   - Fix: Add visual calendar grid

2. **Status Tracking**
   - Argus: Shows manager, approval status
   - Ours: Not implemented
   - Fix: Add status badges

### LOW PRIORITY (Can Mock):
1. **Shift Exchange** - Complex feature
2. **Preferences Mode** - Advanced feature
3. **1C Integration** - External system

## Updated BDD Spec (Matching Reality):

```gherkin
Feature: Employee Personal Cabinet - Real Implementation

Background:
  Given employee portal at "https://lkcc1010wfmcc.argustelecom.ru/"
  And employees access via separate login (not admin portal)

# REALITY: This is what actually exists
Scenario: View Personal Schedule
  When I click "Календарь" in navigation
  Then I see calendar grid (not list)
  And each day shows:
    | Element | Display |
    | Shift time | 09:00-18:00 |
    | Break | 13:00-14:00 (marked differently) |
    | Status | Approved (green) |
  And I can switch views:
    | View | Shows |
    | Month | Full month grid |
    | Week | 7-day detailed |
    | Day | Single day with hours |

# REALITY: Actual request flow
Scenario: Create Vacation Request - Real Flow
  Given I am viewing my calendar
  When I select dates June 15-20
  And right-click or press "Создать заявку"
  Then request form shows:
    | Field | Options |
    | Type | Отпуск/Больничный/Отгул ONLY |
    | Dates | Pre-filled from selection |
    | Manager | Auto-selected based on my team |
    | Comments | Optional text field |
  When I submit
  Then I see "Заявка №12345 отправлена"
  And request appears in "Заявки" > "Текущие"

# REALITY: What's NOT in the product
Scenario: Features in BDD but NOT in Argus
  These don't exist:
  - Shift bidding system
  - Complex approval chains  
  - Multiple request subtypes
  - Integration with external systems visible to employees
```

## Implementation Checklist:

### Must Have for Demo:
- [ ] Calendar grid component (use existing React calendar library)
- [ ] Basic request form with 3 types only
- [ ] Simple status display (Pending/Approved/Rejected)
- [ ] Connect to existing endpoints

### Nice to Have:
- [ ] Color coding for different shift types
- [ ] Drag-select for date ranges
- [ ] Print schedule function

### Skip for Demo:
- [ ] Shift exchange (too complex)
- [ ] Preferences (not critical)
- [ ] Mobile app (just ensure responsive)

## Key Insight:
The actual product is SIMPLER than our BDD specs suggest. Focus on the core calendar + request flow, not theoretical features from documentation.