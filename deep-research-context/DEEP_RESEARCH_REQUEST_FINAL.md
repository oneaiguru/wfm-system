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
    "should_exist": ["OptimizationEngine.tsx", "AIScheduler.tsx"],
    "partial_implementation": ["TemplateManager.tsx"]
  },
  "api_registry": [
    {"endpoint": "/api/v1/schedules", "methods": ["GET", "POST"], "status": "implemented"},
    {"endpoint": "/api/v1/optimize", "methods": ["POST"], "status": "missing"}
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
- R7 found only 25 of 86 scenarios in scheduling domain
- R1 discovered 25+ APIs that weren't documented
- R0 found entire monitoring module missing from specs
- Hidden features comprise 40-60% of actual system

Domain packages solve this by pre-loading:
- Complete scenario lists per domain
- Direct navigation paths
- Component/API existence mapping
- Known gaps and discoveries

---

**Note**: Focus on creating practical, immediately usable packages. We can run another Deep Research if refinements are needed (we have 250 queries/month available).