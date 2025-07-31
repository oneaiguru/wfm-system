# Agent-Based Spec Mapping

## 🤖 Purpose
Shows which agent needs to implement each spec component.

## 📁 Files
- `D-implemented.md` - Database tables, schemas, data requirements
- `E-implemented.md` - API endpoints, integrations, services
- `U-implemented.md` - UI components, forms, user interactions
- `A-implemented.md` - Algorithms, calculations, ML models

## 🔍 Usage Pattern
When R finds a spec mismatch:
1. Check which agents are involved
2. Send targeted messages with specific requirements
3. Coordinate fixes across agents
4. Verify integration after fixes

## 📊 Example Entry
```markdown
SPEC-019: Vacation Request Submission
- D: vacation_requests table ✅
- E: POST /api/v1/requests/vacation ✅
- U: VacationRequestForm.tsx ✅
- A: Leave balance calculation ✅
Status: 90% match (missing holiday validation)
```

## 🎯 Benefits
- Clear ownership mapping
- Targeted fix coordination
- Reduced communication overhead
- Faster issue resolution