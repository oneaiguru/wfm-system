# ⚠️ DEEP RESEARCH: CRITICAL INSTRUCTIONS

## ANALYZE ONLY THESE FOLDERS:
✅ **argus-reality-only/** - ONLY verified findings from real Argus system
✅ **bdd-specs/** - Feature specifications (when created)

## COMPLETELY IGNORE THESE FOLDERS:
❌ **our-implementation/** - Our WFM replica code (NOT Argus)
❌ **verified-knowledge/** - Old polluted data (if still exists)
❌ Any files with `/api/v1/*` REST endpoints
❌ React components (.tsx files)
❌ FastAPI routes

## ARGUS SYSTEM REALITY:
- **Framework**: JSF/PrimeFaces (NOT React)
- **URLs**: End with `.xhtml` (NOT REST endpoints)
- **Requests**: POST with ViewState parameter (NOT JSON)
- **AJAX**: Uses `PrimeFaces.ab()` function
- **UI**: Russian language interface
- **Session**: 22-minute timeout with ViewState management
- **NO REST APIs EXIST IN ARGUS**

## EXAMPLE OF REAL ARGUS FINDINGS:
```
✅ CORRECT: "/ccwfm/views/env/monitoring/MonitoringDashboardView.xhtml"
❌ WRONG: "/api/v1/monitoring/dashboard"

✅ CORRECT: "PrimeFaces.ab({s:'form:button',p:'form:button'})"
❌ WRONG: "fetch('/api/v1/data')"
```

## YOUR TASK:
Create domain packages based ONLY on what exists in argus-reality-only/ folder.
Do NOT speculate or add fictional APIs.