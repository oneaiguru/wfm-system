# Comprehensive Answers to Deep Research Questions

## Answer to Question 1: Should I analyze and segment all 586 BDD scenarios from /specs/working/*.feature to define the 8–10 domains, or are any domains already defined that I should use as a starting point?

### YES - Analyze All 586 Scenarios But Use Our Starting Point

**Starting Point - Current R-Agent Domains (8 domains):**

We currently have 8 R-agents with domain assignments, but these were done hastily and have problems:

1. **R1-AdminSecurity** - 72 scenarios (Admin, Security, Roles, Authentication)
2. **R2-Employee** - 68 scenarios (Employee Self-Service, Personal Dashboard) 
3. **R3-Schedule** - 117 scenarios (Scheduling, Shifts, Templates)
4. **R4-Forecast** - 73 scenarios (Forecasting, Analytics, What-if)
5. **R5-Manager** - 15 scenarios (Manager Dashboard, Approvals)
6. **R6-Integration** - 130 scenarios (Cross-system, External APIs, Zup)
7. **R7-Reports** - 66 scenarios (Reporting, Compliance, Analytics)
8. **R8-Mobile** - 24 scenarios (Mobile App, Responsive UI)

**CRITICAL PROBLEMS WITH CURRENT ASSIGNMENT:**

1. **Imbalanced**: R3 has 117 scenarios, R5 only has 15!
2. **Poor clustering**: Many scenarios are in wrong domains
3. **R7 confusion**: They claimed 100% complete but only verified 25/86 scenarios
4. **Missing coverage**: Some scenarios aren't assigned to anyone

**Your Task**: Re-analyze all 586 scenarios and create OPTIMAL domain packages that:
- Balance workload (60-75 scenarios per domain ideally)
- Group by functional affinity (>85% component reuse within domain)
- Minimize cross-domain dependencies (<5%)
- Ensure 100% coverage with no gaps

**Reference Previous Analysis**: See `/deep-research-context/FROM_DEEP_RESEARCH_TO_ALL_DOMAIN_OPTIMIZATION_RESULTS.md` for how domains were analyzed before. That analysis recommended 8 domains as optimal but you should validate this.

## Answer to Question 2: For each domain package (under 80KB), should the API/component registry include only verified items from /deep-research-context/verified-knowledge/, or should I also include references from /src/components/ and /api/routes/ even if not yet verified?

### INCLUDE BOTH - But Clearly Mark Status

**Structure each domain package with THREE categories:**

```json
{
  "domain": "R7-SchedulingOptimization",
  "components": {
    "verified_exist": [
      // From /deep-research-context/verified-knowledge/components/
      "ScheduleView.tsx",       // ✅ Verified working
      "ShiftGrid.tsx",         // ✅ Verified working
      "ScheduleEditor.tsx"     // ✅ Verified working
    ],
    "found_in_codebase": [
      // From /src/components/ but NOT in verified-knowledge
      "OptimizationEngine.tsx",  // ❓ Found but not verified
      "AIScheduler.tsx",         // ❓ Found but not verified
      "GanttChart.tsx"          // ❓ Found but not verified
    ],
    "should_exist": [
      // Referenced in BDD specs but NOT found anywhere
      "ScheduleOptimizer.tsx",   // ❌ Missing - needs creation
      "ConflictResolver.tsx"     // ❌ Missing - needs creation
    ]
  },
  "api_registry": [
    {
      "endpoint": "/api/v1/schedules",
      "methods": ["GET", "POST"],
      "status": "verified_working",  // From verified-knowledge
      "source": "verified-knowledge/api/ALL_ENDPOINTS_DOCUMENTED.md"
    },
    {
      "endpoint": "/api/v1/schedules/optimize",
      "methods": ["POST"],
      "status": "found_not_verified",  // From /api/routes/
      "source": "api/routes/schedule.py",
      "note": "Endpoint exists but returns mock data"
    },
    {
      "endpoint": "/api/v1/schedules/ai-suggest",
      "methods": ["POST"],
      "status": "missing",  // Referenced in BDD but not found
      "required_by": ["SPEC-24-001", "SPEC-24-002"],
      "note": "BDD expects this but not implemented"
    }
  ]
}
```

**Why This Matters**:
- Agents waste 60-75% of time searching for what exists
- By knowing "verified" vs "found" vs "missing", agents can:
  - Use verified components with confidence
  - Test unverified components to confirm they work
  - Skip searching for missing components and build them

**Sources to Check**:
1. `/deep-research-context/verified-knowledge/` - R-agents verified these work
2. `/src/components/` - All React components in codebase
3. `/api/routes/` - All API endpoints defined
4. `/tests/` and `/e2e-tests/` - Shows what's actually tested
5. BDD specs themselves - Reference components/APIs that SHOULD exist

## Answer to Question 3: Is there a preferred naming or indexing scheme (e.g., for scenario IDs or agent IDs) that the packages should follow to remain consistent with the rest of your tooling?

### YES - Follow These Exact Naming Conventions

**Scenario IDs (Already in registry.json):**
```
Format: SPEC-{NN}-{MMM}
Where: 
- NN = Two-digit feature file number (01-42)
- MMM = Three-digit scenario number within that file (001-999)

Examples:
- SPEC-05-001 = First scenario in 05-complete-step-by-step-requests.feature
- SPEC-24-007 = Seventh scenario in 24-automatic-schedule-optimization.feature
```

**Domain/Agent Names:**
```
Format: R{N}-{DomainName}
Where:
- N = Single digit (1-8 or 1-10 depending on final count)
- DomainName = CamelCase descriptive name

Current (to improve):
- R1-AdminSecurity
- R2-Employee
- R3-Schedule
- R7-Reports (confusion here!)

Better naming:
- R1-SecurityAdmin
- R2-EmployeeSelfService  
- R3-SchedulingOperations
- R7-ReportingAnalytics
```

**Domain Package Files:**
```
/DOMAIN_PACKAGES/
├── R1_SecurityAdmin_Package.json
├── R2_EmployeeSelfService_Package.json
├── R3_SchedulingOperations_Package.json
├── R4_ForecastingAnalytics_Package.json
├── R5_ManagerDashboard_Package.json
├── R6_SystemIntegration_Package.json
├── R7_ReportingAnalytics_Package.json
├── R8_MobileExperience_Package.json
├── COMMON_KNOWLEDGE_Package.json
└── PROGRESSIVE_LOADING_STRATEGY.json
```

**Package Version Scheme:**
```json
{
  "package_version": "1.0",
  "created_date": "2025-07-31",
  "total_scenarios": 73,
  "verified_components": 45,
  "missing_components": 12
}
```

## Additional Critical Information You Need

### The 200K Token Context Problem

**CRITICAL**: Agents die at 95% context usage (190K tokens). This is THE fundamental constraint.

Current agent behavior:
- Load context: ~40K tokens
- Search for components: ~80K tokens (wasteful!)
- Try to understand system: ~60K tokens
- Actual work: ~20K tokens
- DIES before completing task

With domain packages:
- Load domain package: ~50K tokens (includes everything they need)
- Load specific BDD file: ~20K tokens  
- Actual work: ~100K tokens
- Buffer: ~30K tokens
- SUCCESS - completes multiple scenarios

### R7's Specific Confusion

R7-Reports claimed 100% completion but investigation shows:
- Total scenarios assigned: 86
- Actually verified: 25
- Status in their progress file: "100% complete" (?!)
- Problem: They may have been checking wrong system or misunderstanding task

**For Deep Research**: Please re-examine R7's domain (Reports/Analytics) carefully. The 66 scenarios currently assigned might need redistribution.

### Hidden Features Problem

R-agents discovered 40-60% more features than documented:
- R0: Found entire monitoring module not in specs
- R1: Found 25+ security APIs not documented
- R2: Found employee profile management system
- R5: Found "Exchange" (Биржа) shift marketplace
- R8: Found push notifications, PWA features

**For Domain Packages**: Include a "discovery_hints" section:
```json
{
  "discovery_hints": {
    "likely_hidden_features": [
      "Check for monitoring endpoints under /api/v1/monitoring/*",
      "Look for shift marketplace UI components",
      "Test for push notification registration endpoints"
    ],
    "exploration_patterns": [
      "Use browser DevTools to see all API calls",
      "Check for feature flags in settings",
      "Look for commented code mentioning features"
    ]
  }
}
```

### Integration Patterns Discovered

From `/deep-research-context/INTEGRATION_PATTERNS_LIBRARY_UPDATED.md`:

1. **Pattern-1**: Route Granularity Mismatch
2. **Pattern-2**: Form Field Name Attributes  
3. **Pattern-3**: API Endpoint URL Construction
4. **Pattern-4**: Role-Based Route Handling
5. **Pattern-5**: Test Selector Availability
6. **Pattern-6**: Performance vs Functionality Trade-offs
7. **Pattern-7**: Calendar Integration (expected)
8. **Pattern-8**: Date/Time Handling (expected)
9. **Pattern-9**: Session Management (expected)
10. **Pattern-10**: External System Integration

Include relevant patterns in each domain package so agents know what problems to expect.

### Argus Demo System Details

**CRITICAL**: We're verifying against Argus (Russian WFM system):
- URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/
- Language: Russian UI (not English!)
- Tech: JSF (admin portal) + Vue.js (employee portal)
- Auth: ViewState (admin) vs JWT (employee)

Domain packages should include:
```json
{
  "argus_navigation": {
    "admin_portal": {
      "base_url": "/ccwfm/views/env/",
      "tech_stack": "JSF/ViewState",
      "ui_language": "Russian"
    },
    "employee_portal": {
      "base_url": "/mobile/",
      "tech_stack": "Vue.js/JWT",
      "ui_language": "Russian"
    }
  }
}
```

### Expected Output Structure

Create these files in `/project/deep-research-context/DOMAIN_PACKAGES/`:

1. **Individual Domain Packages** (8-10 files, 50-80KB each):
   - R1_SecurityAdmin_Package.json
   - R2_EmployeeSelfService_Package.json
   - etc.

2. **Common Knowledge Package** (1 file, <30KB):
   - COMMON_KNOWLEDGE_Package.json
   - Contains shared patterns, auth info, project structure

3. **Progressive Loading Strategy** (1 file, <10KB):
   - PROGRESSIVE_LOADING_STRATEGY.json
   - Instructions for agents on when to load what

4. **Coverage Verification Matrix** (1 file):
   - DOMAIN_COVERAGE_MATRIX.csv or .json
   - Shows all 586 scenarios mapped to domains
   - Identifies any gaps or overlaps

5. **Implementation Instructions** (1 file):
   - AGENT_IMPLEMENTATION_GUIDE.md
   - How to use the packages
   - Daily targets and success metrics

Remember: The goal is to transform agent discovery from 25-40% → 95%+ by pre-loading all knowledge they need!