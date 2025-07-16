# 📋 SUBAGENT TASK: Fix Approval Engine

## 🎯 Task Information
- **Task ID**: FIX_APPROVAL_ENGINE
- **File**: src/algorithms/workflows/approval_engine.py
- **Priority**: Critical
- **Pattern**: Mobile Workforce Scheduler fix

## 🚨 Current Problem
- Likely uses mock approval data
- May query non-existent workflow tables
- Returns simulated approval results

## 🔧 Fix Pattern (From Mobile Workforce Success)
1. **Find Real Tables**: 
   ```bash
   psql -U postgres -d wfm_enterprise -c "\dt" | grep -E "(approval|request|workflow)"
   ```
2. **Check Current Queries**: Analyze what tables the algorithm tries to access
3. **Map to Real Schema**: 
   - Look for: employee_requests, vacation_requests, approval_chains
   - Check columns: status, approved_by, approval_date
4. **Test with Real Data**: Verify processes real approval requests
5. **Performance Check**: Should complete <1s for approval decisions

## 📊 Expected Real Tables to Use
- employee_requests (has approval workflow)
- vacation_requests (needs approval)
- cross_system_approvals (if exists)
- approval_audit_trail (for history)

## ✅ Success Criteria
- [ ] Processes real approval requests (not mock)
- [ ] Uses actual database tables only
- [ ] Returns real employee/manager relationships
- [ ] Performance <1s for single approval
- [ ] Handles approval chains correctly

## 🧪 Verification Commands
```python
# Test algorithm with real data
from src.algorithms.workflows.approval_engine import ApprovalEngine
engine = ApprovalEngine()
pending = engine.get_pending_approvals()
assert len(pending) > 0  # Should find real pending requests
assert all(r.get('employee_id') for r in pending)  # Real employee IDs
print(f"Found {len(pending)} real approval requests")

# Test approval processing
result = engine.process_approval(pending[0]['id'], 'approved', manager_id='...')
assert result['success']  # Should update real database
```

## 🔍 Common Issues to Fix
1. Replace mock approval queue with real employee_requests query
2. Fix manager hierarchy lookups to use real employees table
3. Update approval rules to match business logic
4. Connect to real notification system (if applicable)

## 📋 BDD Compliance
- Check relevant BDD files for approval workflow requirements
- Ensure multi-level approval chains work
- Verify delegation and escalation logic