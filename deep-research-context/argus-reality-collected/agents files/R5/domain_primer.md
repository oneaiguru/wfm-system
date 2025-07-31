# R5-ManagerOversight Domain Primer

## 🎯 Your Domain: Manager Functions
- **Scenarios**: 15 total (4 demo-critical)
- **Features**: Approvals, team dashboard, schedule management

## 📊 Domain-Specific Details

### Primary Components
- `ManagerDashboard.tsx` - Team overview
- `TeamManagement.tsx` - Team operations
- `ApprovalQueue.tsx` - Request approvals

### Primary APIs
- `/api/v1/requests/pending-approval`
- `/api/v1/team/schedule`
- `/api/v1/manager/metrics`

### Known Patterns
- **Pattern 4**: Role-based routes (`/manager/*` paths)
- **Pattern 5**: Dashboard test IDs
- **Pattern 6**: Performance vs functionality

### Quick Wins (Start Here)
- SPEC-06-001: Manager login
- SPEC-06-002: View approval queue
- SPEC-07-001: Team dashboard access

## 🔄 Dependencies
- **Depends on**: R-EmployeeSelfService (needs requests to approve)
- **Provides to**: R-ReportingCompliance (approval data)

## 💡 Domain Tips
1. Ensure `/manager` routes don't redirect to employee pages
2. All dashboard widgets need `data-testid`
3. Use manager test users (jane.manager/test)
4. Approval flow requires pending requests (from Employee)