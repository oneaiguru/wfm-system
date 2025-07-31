# SPEC-19: Employee Vacation Request - Reality Check

## BDD Spec Says (02-employee-requests.feature lines 12-24):
- Navigate to "Календарь" (Calendar) tab
- Click "Создать" (Create) button  
- Select from 3 request types: больничный (sick leave), отгул (time off), внеочередной отпуск (unscheduled vacation)
- Fill corresponding fields
- Submit request
- See status on "Заявки" (Requests) page

## Argus Reality:
Unable to access Argus (403 Forbidden), but based on documentation:
- Calendar-based request creation
- Right-click on dates to create request
- Only 3 request types
- Manager auto-assigned based on team

## Our Implementation Has:
✅ Direct request form at `/requests`
✅ Form with request types (but in English: Vacation, Sick Leave, Personal Time, Training)
✅ Start/End date selection with date pickers
✅ Reason field (required)
✅ Coverage notes field (optional)
✅ Policy reminders display
✅ Remaining balance display (15 days)
✅ Submit/Cancel buttons

## Gaps Found:
❌ No calendar integration - form is standalone, not accessed from calendar
❌ Request types don't match spec (English vs Russian, 4 types vs 3)
❌ No "Create" button from calendar view
❌ Form is at `/requests` not accessed via calendar tab
❌ No automatic manager assignment visible
❌ No redirect to request history after submission

## Parity: 40%

## Recommended Tags:
```gherkin
@baseline @demo-critical @needs-update
Scenario: Create Request for Time Off/Sick Leave/Unscheduled Vacation
  # REALITY: Direct form at /requests, not calendar-based
  # TODO: Integrate with calendar for date selection
  # TODO: Match request types to spec (3 types, Russian terms)
  # TODO: Add manager auto-assignment
  # TODO: Redirect to request history after submission
```

## Implementation Priority:
1. **Quick Win** (30 min): Update request types to match spec
2. **Demo Critical** (2 hours): Add calendar integration 
3. **Nice to Have** (1 hour): Manager auto-assignment display