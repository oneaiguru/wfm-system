# BDD Spec Master Index

## 🎯 Purpose
Quick discovery of all BDD scenarios for efficient verification by R (REALITY-CHECK-AGENT).

## 📊 Index Format
Each entry follows this pattern:
```
SPEC-XXX: [Scenario Name]
File: [filename.feature:line-range]
Status: [@tag] [✅ verified | ⏳ pending | ❌ mismatch]
Reality: [X% match]
Agents: [D, E, U, A involvement]
```

## 🔍 Quick Search Commands
```bash
# Find by SPEC number
grep "SPEC-019" MASTER_INDEX.md

# Find verified specs
grep "✅ verified" MASTER_INDEX.md

# Find by feature area
grep -i "vacation\|schedule\|dashboard" MASTER_INDEX.md

# Find specs needing work
grep "⏳ pending\|❌ mismatch" MASTER_INDEX.md
```

## 📋 Current Specs (Sample - R to populate)

### Authentication & Access
SPEC-001: Employee logs into the system
File: authentication.feature:10-25
Status: @baseline ✅ verified
Reality: 100% match
Agents: U (login form), E (auth endpoint), D (sessions table)

SPEC-002: Employee logout and session management
File: authentication.feature:27-40
Status: @baseline ✅ verified
Reality: 100% match
Agents: U (logout button), E (logout endpoint), D (session cleanup)

### Vacation Requests
SPEC-019: Employee submits vacation request
File: vacation-request.feature:45-67
Status: @verified ✅ verified
Reality: 90% match (no holiday validation)
Agents: U (form), E (POST endpoint), D (requests table)

SPEC-020: Manager approves vacation request
File: vacation-request.feature:69-95
Status: @verified ✅ verified
Reality: 95% match
Agents: U (approval UI), E (PUT endpoint), D (approval_history)

### Employee Dashboard
SPEC-037: Employee views personal dashboard
File: employee-dashboard.feature:15-35
Status: @baseline ✅ verified
Reality: 100% match
Agents: U (Dashboard.tsx), E (metrics endpoints), D (employee_metrics)

### Manager Features
SPEC-042: Manager views team dashboard
File: manager-dashboard.feature:20-45
Status: @verified ✅ verified
Reality: 100% match
Agents: U (ManagerDashboard.tsx), E (team endpoints), D (team_assignments)

## 📈 Verification Progress
- Total SPECs: 580
- Verified: [R to update]
- Pending: [R to update]
- Mismatch: [R to update]
- Coverage: [X%]

## 🔄 Update Protocol
1. R verifies a scenario
2. Updates this index with results
3. Adds to appropriate by-status/ file
4. Updates by-feature/ categorization
5. Maps to by-agent/ involvement

---
Last Updated: 2025-07-25 by O (initial structure)