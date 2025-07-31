# Deep Research Request: Create Informed Agent Domain Packages for WFM System Coverage

## Executive Context

We have a critical constraint: agents operating with 200K token limits are discovering only 25-40% of system features because they work blind. We need to create "Informed Agent" packages that pre-load domain knowledge, enabling systematic 95%+ coverage.

## Research Objective

Analyze our WFM repository to create optimized domain packages for 8-10 specialized agents, ensuring complete system coverage without context exhaustion. Each agent should know WHAT exists before exploring HOW it works.

## Repository Structure

```
/project/
├── specs/working/*.feature (42 files, 586 BDD scenarios)
├── src/components/ (100+ React components)
├── api/routes/ (147 REST endpoints)
├── tests/ (integration and unit tests)
├── e2e-tests/ (end-to-end test coverage)
└── deep-research-context/
    ├── registry_updated.json (all 586 scenarios with metadata)
    ├── verified-knowledge/
    │   ├── components/ALL_COMPONENTS_VERIFIED.md
    │   ├── api/ALL_ENDPOINTS_DOCUMENTED.md
    │   ├── database/ALL_TABLES_761_VERIFIED.md
    │   ├── algorithms/ALGORITHMS_REGISTRY.md
    │   └── navigation/ (to be populated)
    └── r-agent-reports/
        └── FROM_R1_TO_META_R_API_DISCOVERY_STATUS_2025_07_31.md
```

## Specific Deliverables Required

### 1. Domain Separation Analysis

Analyze all 586 BDD scenarios in `/specs/working/*.feature` and separate into 8-10 domains based on:
- Business function clustering (employee, manager, scheduling, etc.)
- Technical component reuse (>85% within domain)
- Cross-domain dependencies (<5% coordination needed)
- Balanced workload (60-75 scenarios per domain)

### 2. Domain Package Structure (JSON format, <80KB each)

```json
{
  "domain": "R7-SchedulingOptimization",
  "package_version": "1.0",
  "token_budget": {
    "total": 200000,
    "package_size": 50000,
    "working_space": 100000,
    "conversation": 50000
  },
  "scenario_index": [
    {
      "id": "SPEC-24-001",
      "name": "AI-based schedule optimization",
      "file": "24-automatic-schedule-optimization.feature",
      "line": 45,
      "priority": "demo-critical",
      "url_hint": "/scheduling/optimize"
    }
    // ... all scenarios in domain
  ],
  "navigation_map": {
    "base_urls": {
      "admin_portal": "/ccwfm/views/env/scheduling/",
      "employee_portal": "/mobile/schedule/"
    },
    "key_pages": [
      {"name": "Schedule Grid", "url": "/schedule/grid", "portal": "admin"},
      {"name": "Template Manager", "url": "/templates", "portal": "admin"}
    ],
    "state_sequences": [
      "login → dashboard → scheduling → create",
      "login → templates → apply → publish"
    ]
  },
  "components": {
    "verified_exist": ["ScheduleView.tsx", "ShiftGrid.tsx"],
    "found_in_codebase": ["OptimizationEngine.tsx", "AIScheduler.tsx"],
    "should_exist": ["ScheduleOptimizer.tsx", "ConflictResolver.tsx"]
  },
  "api_registry": [
    {"endpoint": "/api/v1/schedules", "methods": ["GET", "POST"], "status": "verified_working"},
    {"endpoint": "/api/v1/optimize", "methods": ["POST"], "status": "found_not_verified"},
    {"endpoint": "/api/v1/schedules/ai-suggest", "methods": ["POST"], "status": "missing"}
  ],
  "cross_domain_deps": {
    "needs_from": {
      "R5-Manager": ["employee_availability", "approval_status"],
      "R3-Forecast": ["demand_data"]
    },
    "provides_to": {
      "R2-Employee": ["personal_schedule"],
      "R6-Reporting": ["schedule_data"]
    }
  },
  "known_patterns": [
    "Pattern-6: Performance vs Functionality for large grids",
    "Pattern-7: Calendar integration expected"
  ],
  "previous_discoveries": {
    "hidden_features": ["12 scheduling templates found", "Gantt view exists"],
    "blockers": ["Permission required for AI features"]
  }
}
```

### 3. Common Knowledge Package (All Agents)

Create a shared package (<30KB) containing:
- Project structure overview
- Authentication patterns (JSF vs JWT)
- Global navigation structure
- Common UI components
- Coordination protocols
- File size limits and conventions

### 4. Progressive Loading Strategy

```yaml
Phase 1 - Index Only (20KB):
  - Scenario names and IDs
  - Priority markers
  - Basic navigation URLs

Phase 2 - Full Context (50KB):
  - Complete scenario descriptions
  - Component details
  - API specifications
  - Known issues

Phase 3 - Working Memory:
  - Load specific BDD file when needed
  - Summarize after completion
  - Maintain <80% context usage
```

### 5. Coverage Verification Matrix

| Domain | Scenarios | Components | APIs | Dependencies | Priority |
|--------|-----------|------------|------|---------------|----------|
| R1-Security | 72 | 15 | 25 | None | High |
| R2-Employee | 68 | 20 | 18 | R5 | Critical |
| ... | ... | ... | ... | ... | ... |

### 6. Implementation Instructions

For each domain, provide:
1. Quick start commands
2. Verification sequence
3. Success metrics
4. Summarization template
5. Handoff protocol

## Analysis Sources

### Primary Sources (Ground Truth)
- `/specs/working/*.feature` - All 586 BDD scenarios
- `/deep-research-context/registry_updated.json` - Scenario metadata with R-agent assignments

### Implementation Reality
- `/deep-research-context/verified-knowledge/components/` - Verified UI components
- `/deep-research-context/verified-knowledge/api/` - Documented endpoints (147 total)
- `/deep-research-context/verified-knowledge/database/` - 761 verified tables
- `/deep-research-context/verified-knowledge/algorithms/` - Algorithm registry

### Agent Discoveries
- `/deep-research-context/r-agent-reports/` - R1's discovery of 25+ missing APIs
- Previous journey analyses in `/deep-research-context/*JOURNEY*.md`

## Constraints & Requirements

1. **File Size Limits**: Each package must be <80KB (no token counting needed)
2. **No Overlaps**: Each scenario assigned to exactly one domain
3. **Complete Coverage**: All 586 scenarios must be assigned
4. **MCP Awareness**: Include URLs for MCP browser automation
5. **Reality Grounding**: Reference implementation status from verified-knowledge

## Analysis Priorities

1. **High**: Demo-critical scenarios (Value=5)
2. **Medium**: Core business workflows
3. **Low**: Edge cases and error handling

## Expected Outcomes

With these domain packages:
- Agents achieve 95%+ scenario discovery (vs current 25-40%)
- Context usage stays <80% throughout 4+ hour sessions
- Zero duplicate work between agents
- Systematic verification replaces random exploration
- Complete API/component mapping in 2 weeks (vs 4-6 weeks)

## Success Metrics

1. Each agent can list all their scenarios without searching
2. Navigation is direct (no exploration needed)
3. Cross-domain coordination <5% of effort
4. 4+ hour sessions without context exhaustion
5. 20+ scenarios/day throughput per agent

## Critical Context: The 25% Discovery Problem

Current situation demonstrates the problem:
- R7 found only 25 of 86 scenarios (claimed 100% but was wrong/irrelevant)
- R1 discovered 25+ APIs that weren't documented
- R0 found entire monitoring module missing from specs
- Hidden features comprise 40-60% of actual system

Domain packages solve this by pre-loading:
- Complete scenario lists per domain
- Direct navigation paths
- Component/API existence mapping
- Known gaps and discoveries

---

## COMPREHENSIVE ANSWERS TO YOUR SPECIFIC QUESTIONS

### Question 1: Should I analyze and segment all 586 BDD scenarios from /specs/working/*.feature to define the 8–10 domains, or are any domains already defined that I should use as a starting point?

**YES - Analyze all 586 scenarios but use our problematic starting point as reference**

We currently have 8 R-agents with hastily assigned domains that have major problems:

**Current Assignments (PROBLEMATIC):**
1. R1-AdminSecurity - 72 scenarios
2. R2-Employee - 68 scenarios  
3. R3-Schedule - 117 scenarios (TOO MANY!)
4. R4-Forecast - 73 scenarios
5. R5-Manager - 15 scenarios (TOO FEW!)
6. R6-Integration - 130 scenarios (TOO MANY!)
7. R7-Reports - 66 scenarios (but only verified 25 - mostly irrelevant/confused)
8. R8-Mobile - 24 scenarios

**Critical Problems:**
- Severely imbalanced (R3: 117 vs R5: 15)
- Poor functional clustering
- R7 confusion (claimed 100% but only did 25/86)
- Some scenarios not assigned to anyone

**Your Task:** Re-analyze and create OPTIMAL assignments with 60-75 scenarios per domain.

**Reference:** See `/deep-research-context/FROM_DEEP_RESEARCH_TO_ALL_DOMAIN_OPTIMIZATION_RESULTS.md` for previous Deep Research that recommended 8 domains. Validate if 8 is still optimal or if 9-10 would be better.

### Question 2: For each domain package (under 80KB), should the API/component registry include only verified items from /deep-research-context/verified-knowledge/, or should I also include references from /src/components/ and /api/routes/ even if not yet verified?

**INCLUDE ALL THREE CATEGORIES - Clearly Marked by Status**

Structure each package with THREE distinct categories:

```json
{
  "components": {
    "verified_exist": [
      // From /deep-research-context/verified-knowledge/
      "ScheduleView.tsx",      // ✅ R-agents confirmed working
      "ShiftGrid.tsx"          // ✅ R-agents confirmed working
    ],
    "found_in_codebase": [
      // From /src/components/ but NOT verified
      "OptimizationEngine.tsx", // ❓ Exists but untested
      "AIScheduler.tsx"         // ❓ Exists but untested
    ],
    "should_exist": [
      // Referenced in BDD but NOT found anywhere
      "ScheduleOptimizer.tsx",  // ❌ Missing - needs creation
      "ConflictResolver.tsx"    // ❌ Missing - needs creation
    ]
  },
  "api_registry": [
    {
      "endpoint": "/api/v1/schedules",
      "methods": ["GET", "POST"],
      "status": "verified_working",
      "source": "verified-knowledge/api/ALL_ENDPOINTS_DOCUMENTED.md",
      "returns_real_data": true
    },
    {
      "endpoint": "/api/v1/schedules/optimize",
      "methods": ["POST"],
      "status": "found_not_verified",
      "source": "api/routes/schedule.py",
      "note": "Endpoint exists but may return mock data"
    },
    {
      "endpoint": "/api/v1/schedules/ai-suggest",
      "methods": ["POST"],
      "status": "missing",
      "required_by": ["SPEC-24-001", "SPEC-24-002"],
      "note": "BDD expects this but not implemented"
    }
  ]
}
```

**Why This Matters:** Agents waste 60-75% of context searching. By knowing status upfront, they can skip searching for missing items and focus on building/testing.

### Question 3: Is there a preferred naming or indexing scheme (e.g., for scenario IDs or agent IDs) that the packages should follow to remain consistent with the rest of your tooling?

**YES - Use These Exact Conventions**

**Scenario IDs (from registry.json):**
```
Format: SPEC-{NN}-{MMM}
- NN = Two-digit feature file number (01-42)
- MMM = Three-digit scenario number (001-999)

Examples:
- SPEC-05-001 = 05-complete-step-by-step-requests.feature, scenario 1
- SPEC-24-007 = 24-automatic-schedule-optimization.feature, scenario 7
```

**Domain/Agent Naming:**
```
Format: R{N}-{DomainName}
Better names than current:
- R1-SecurityAdmin (not AdminSecurity)
- R2-EmployeeSelfService (not Employee)
- R3-SchedulingOperations (not Schedule)
- R7-ReportingAnalytics (not Reports)
```

**Package File Names:**
```
/DOMAIN_PACKAGES/
├── R1_SecurityAdmin_Package.json
├── R2_EmployeeSelfService_Package.json
├── COMMON_KNOWLEDGE_Package.json
└── PROGRESSIVE_LOADING_STRATEGY.json
```

## ADDITIONAL CRITICAL CONTEXT

### The 200K Token Death Problem

Agents DIE at 95% context (190K tokens). Current wasteful pattern:
- Load context: 40K
- Search for components: 80K (WASTE!)
- Try to understand: 60K
- Actual work: 20K
- DIES before completing

With domain packages:
- Load package: 50K (has everything)
- Load BDD file: 20K
- Actual work: 100K
- Buffer: 30K
- SUCCESS!

### R7's Specific Issues (Mostly Irrelevant)

R7-Reports is confused:
- Assigned: 86 scenarios
- Actually verified: 25 only
- Claimed: "100% complete"
- Reality: Probably testing wrong system or misunderstanding

**NOTE TO DEEP RESEARCH:** R7's work is mostly irrelevant. Re-examine their 66 scenarios and likely redistribute them properly.

### Hidden Features (40-60% of System!)

R-agents found massive gaps:
- R0: Entire monitoring module missing
- R1: 25+ security APIs undocumented
- R5: "Exchange" (Биржа) shift marketplace
- R8: Push notifications, PWA features

Include discovery hints in packages:
```json
{
  "discovery_hints": {
    "likely_hidden_features": [
      "Check /api/v1/monitoring/* endpoints",
      "Look for shift marketplace components",
      "Test push notification registration"
    ]
  }
}
```

### Integration Patterns Library

Include relevant patterns from `/deep-research-context/INTEGRATION_PATTERNS_LIBRARY_UPDATED.md`:
1. Pattern-1: Route Granularity
2. Pattern-2: Form Field Names
3. Pattern-3: API URL Construction
4. Pattern-4: Role-Based Routes
5. Pattern-5: Test Selectors
6. Pattern-6: Performance Trade-offs
7-10: Expected new patterns

### Argus System Details (CRITICAL)

We're testing against Russian Argus system:
- URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/
- UI Language: RUSSIAN (not English!)
- Admin: JSF/ViewState technology
- Employee: Vue.js/JWT technology

Include in packages:
```json
{
  "argus_navigation": {
    "admin_portal": {
      "base_url": "/ccwfm/views/env/",
      "tech": "JSF/ViewState",
      "language": "Russian"
    },
    "employee_portal": {
      "base_url": "/mobile/",
      "tech": "Vue.js/JWT",
      "language": "Russian"
    }
  }
}
```

### Expected Deliverables Location

Create these in `/project/deep-research-context/DOMAIN_PACKAGES/`:
1. 8-10 domain packages (50-80KB each)
2. COMMON_KNOWLEDGE_Package.json (<30KB)
3. PROGRESSIVE_LOADING_STRATEGY.json
4. DOMAIN_COVERAGE_MATRIX.csv
5. AGENT_IMPLEMENTATION_GUIDE.md

The goal: Transform discovery from 25-40% → 95%+ by pre-loading all knowledge!

---

**Note**: This comprehensive request provides all context needed. Previous Deep Research analysis from July 2025 is available at `/deep-research-context/FROM_DEEP_RESEARCH_TO_ALL_DOMAIN_OPTIMIZATION_RESULTS.md` for reference on how domains were analyzed before.