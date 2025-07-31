# SPEC-23: Request History Analysis

**BDD Spec**: 02-employee-requests.feature lines 84-93
**Feature**: Request Status Tracking
**Demo Value**: 5 (High Priority)

## What BDD Says
1. Requests should progress through statuses: Создана → На рассмотрении → Одобрена/Отклонена
2. All parties should see current status
3. Support for 4 request types: больничный (sick leave), отгул (time off), внеочередной отпуск (unscheduled vacation), обмен сменами (shift exchange)

## What We Have
✅ Request history with tabs (Active/Pending/History)
✅ Status tracking showing final status (Approved/Rejected)
✅ Filtering by type and sorting options
✅ Search functionality
✅ Detailed view modal with approval info
✅ Shows reviewer and comments

❌ No intermediate status progression visible (only final status)
❌ Wrong request types: Vacation, Sick Leave, Time Off, Shift Change, Overtime (not matching spec)
❌ API error when fetching history (falls back to mock data)
❌ No real-time status updates for all parties

## Integration Issues
- API endpoint `/api/v1/requests/employee/1/history` returns CORS error
- WebSocket connection fails for real-time updates
- Using mock data instead of real backend

## Parity Score: 60%

## Rationale
- Basic history functionality works with good UI
- Status tracking exists but doesn't show progression
- Request types don't match spec terminology
- Real-time visibility for "all parties" not implemented
- API integration broken but UI compensates with mock data

## Tags to Apply
- @baseline (core functionality)
- @demo-critical (high priority feature)
- @needs-enhancement (status progression, correct types)
- @api-integration-required (fix CORS, WebSocket)