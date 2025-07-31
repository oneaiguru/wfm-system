# R2-EmployeeSelfService Domain Primer

## 🎯 Your Domain: Employee Self-Service Features
- Primary Features: Vacation requests, personal schedule, employee portal, profile management
- Scenario Count: 57 total
- Demo Priority: 5 Value 5 scenarios (SPEC-019, SPEC-022, SPEC-045, SPEC-067, SPEC-089)

## 📊 Domain Statistics
- **Total Scenarios**: 57
- **Demo Value 5**: 5 scenarios (highest priority)
- **Quick Wins**: Employee dashboard, vacation request form, personal schedule view
- **Complex Areas**: Offline mode, shift swap negotiations
- **Component Reuse**: 87% within domain (RequestForm.tsx used everywhere)
- **Primary Patterns**: Pattern 1 (route fixes), Pattern 2 (form fields), Pattern 3 (API paths), Pattern 5 (test IDs)

## 🌐 Your Ground Truth
### Argus Pages (saved locally):
- `employee_personal_cabinet.html` - Main employee portal
- `vacation_request_flow.html` - Complete vacation process
- `personal_schedule_view.html` - Schedule management
- `profile_settings.html` - Employee profile updates

### Integration Patterns:
- Pattern 1: Route granularity - Add specific employee routes missing
- Pattern 2: Form accessibility - Ensure all form fields have proper names
- Pattern 3: API construction - Check endpoint patterns match
- Pattern 5: Test IDs - Add data-testid for automation

## 🔄 Coordination Points
- **Dependencies on**: R-AdminSecurity (must have auth working first)
- **Provides to**: R-ManagerOversight (vacation requests for approval)

## 💡 Domain-Specific Tips

### 1. Start with Login
Always verify login works before testing other features

### 2. Vacation Flow is Golden
The vacation request journey is 90% working - great for quick wins:
- Create request → View in dashboard → Check calendar integration

### 3. Common Gotchas
- Mobile views use different routes (/mobile/employee vs /employee)
- Shift swap requires 2 logged-in users (use incognito for second)
- Profile photo upload is stubbed - mark as partial parity