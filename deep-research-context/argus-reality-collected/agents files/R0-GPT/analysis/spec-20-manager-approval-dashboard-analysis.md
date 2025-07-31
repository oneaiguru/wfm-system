# SPEC-20: Manager Approval Dashboard - Reality Check

## BDD Spec Says (03-complete-business-process.feature lines 96-111):
- Supervisor logs in with supervisor role
- Navigate to "Заявки" (Requests) section  
- Select "Доступные" (Available) requests
- Review requests for отгул/больничный/внеочередной отпуск
- Approve or reject requests
- Status updates to "Подтвержден" (Confirmed) or "Отказано" (Rejected)
- Employee work schedule changes reflected
- Employee sees updated status

## Argus Reality:
Unable to access Argus, but based on documentation:
- Manager dashboard with team statistics
- Real-time monitoring capabilities  
- One-click approve/reject actions
- Team coverage impact display
- Drill-down to individual employees

## Our Implementation Has:
✅ Manager Dashboard exists at `/manager-dashboard`
✅ Live data updates shown
✅ Team metrics display (but all zeros)
✅ Manager Tools section with links
✅ Approval Queue link (but route not implemented)
✅ Team performance KPIs section
✅ Recent team activity section

## Gaps Found:
❌ All metrics show zeros - no real data
❌ Approval Queue route returns 404 (/manager/approvals not found)
❌ No actual pending requests displayed
❌ No one-click approve/reject functionality
❌ No team coverage impact calculations
❌ No integration with request system
❌ Dashboard shows "0" for team members, active today, on vacation, pending requests

## Parity: 20%

## Recommended Tags:
```gherkin
@supervisor @step4 @approval @baseline @demo-critical @blocked
Scenario: Supervisor Approve Time Off/Sick Leave/Vacation Request
  # REALITY: Dashboard exists but approval functionality missing
  # BLOCKED: /manager/approvals route not implemented
  # TODO: Implement approval queue with real data
  # TODO: Connect to request management system
  # TODO: Add one-click approve/reject buttons
  # TODO: Show team coverage impact
```

## Implementation Priority:
1. **Critical Blocker** (4 hours): Implement /manager/approvals route and approval queue
2. **Demo Critical** (2 hours): Connect dashboard to real team/request data
3. **High Priority** (1 hour): Add approve/reject functionality with status updates
4. **Nice to Have** (1 hour): Team coverage impact calculations