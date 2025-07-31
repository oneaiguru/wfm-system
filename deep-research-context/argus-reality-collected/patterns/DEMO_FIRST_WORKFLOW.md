# Demo First, Build Second - Mandatory Workflow Pattern

## 🎯 Core Principle
Test existing functionality BEFORE building new components. This prevents 80% false completion rates.

## 📋 Mandatory Workflow for ALL Agents

### Step 1: Demo What Exists
```bash
# Before starting ANY SPEC work, run demos from other agents:
# Example for SPEC-06:

# From DATABASE-OPUS:
psql -U postgres -d wfm_enterprise -c "SELECT * FROM analytics_dashboard"

# From INTEGRATION-OPUS:
curl http://localhost:8000/api/v1/analytics/dashboard

# From UI-OPUS:
npm run dev  # Then check if component renders

# From ALGORITHM-OPUS:
python analytics_engine.py

# Document what ACTUALLY works vs fails
```

### Step 2: Build Only on Verified Foundations
- ✅ If DB query works → use that table
- ✅ If API returns data → integrate with it
- ❌ If API returns 404 → fix endpoint first
- ❌ If table missing → coordinate with DATABASE-OPUS

### Step 3: Create Your Demo Command
```bash
# Your demo must show E2E functionality:
curl -X POST http://localhost:8000/api/v1/auth/login \
  -d '{"username":"john.doe","password":"password123"}' \
  | jq '.token'

# Or for database:
psql -U postgres -d wfm_enterprise -c "SELECT COUNT(*) FROM shift_exchanges"

# Or for algorithm:
python -c "from algorithms.shift_trading import create_trade; print(create_trade('EMP001', 'EMP002', '2025-08-01'))"
```

### Step 4: Report Complete ONLY When Demo Works
```markdown
## SPEC-XX Completion Report
**Status**: ✅ Complete
**Demo Command**: `curl http://localhost:8000/api/v1/feature`
**Demo Output**: 
```json
{
  "status": "success",
  "data": {...}
}
```
**E2E Verified**: User can complete full workflow
```

## ❌ What STOPS Now
- Claiming "complete" because files exist
- Building on untested assumptions  
- Discovery counting as completion
- "It should work" without verification

## ✅ What STARTS Now
- Test first, build second
- Demo commands as proof
- Real E2E functionality
- Honest progress tracking

## 🎯 Special Rules by Agent Type

### BDD-SCENARIO-AGENT (B1/B2)
- Run ALL demo commands from D/I/U/A
- Document exactly what works/fails
- Only mark V-Complete if E2E demo succeeds
- Provide YOUR demo showing full workflow

### DATABASE-OPUS
- Every table creation includes test INSERT
- Show SELECT results with real data
- Verify performance < 100ms

### INTEGRATION-OPUS  
- Every endpoint includes curl demo
- Show real response (not mock)
- Include auth headers if needed

### UI-OPUS
- Component must render without errors
- Show real data from API (not hardcoded)
- Include screenshot or description

### ALGORITHM-OPUS
- Algorithm must run without import errors
- Show real calculation results
- Test with actual database data

## 📊 Success Metrics
- False completion rate: Target 0%
- Demo command availability: 100%
- E2E verification: Required for "complete" status
- Rework prevention: 80%+ reduction

**This pattern is MANDATORY for all agents starting immediately.**