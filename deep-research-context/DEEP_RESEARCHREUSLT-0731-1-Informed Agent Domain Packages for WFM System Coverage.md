Great. I will begin analyzing the WFM system repository to create 8–10 optimized domain packages that ensure over 95% coverage of all 586 BDD scenarios without exhausting the agent's 200K token limit.

I’ll ensure each package includes a complete scenario index, navigation map, component/API registry with status, cross-domain dependencies, hidden features, and progressive loading structure. I’ll also generate a Common Knowledge Package, Coverage Verification Matrix, and Implementation Guide to support agents' success.

I’ll notify you as each deliverable becomes available for review.

# Informed Agent Domain Packages for WFM System Coverage

## Executive Context

Agents operating with large 200K token contexts have been **underperforming**, discovering only ~25–40% of system features because they start **“blind”** without a map of what to look for. This has led to massive gaps: entire modules and APIs remain untested. To reach **95%+ feature coverage**, we will create **“Informed Agent”** domain packages that preload essential knowledge for each agent. By equipping agents with a focused index of scenarios, components, and endpoints per domain, they will know *what exists* in their domain **before** exploring *how it works*, eliminating aimless searching.

Each domain package will serve as a **guidebook** for a specialized agent, ensuring systematic coverage of the WFM system without exhausting context. The goal is to transform verification from random exploration into a targeted, efficient process. This approach directly addresses the current 25% discovery rate problem by front-loading comprehensive domain knowledge and navigation hints.

## Research Objective and Scope

**Objective:** Analyze the entire WFM repository to design **8–10 optimized domain knowledge packages** for parallel agents, ensuring complete coverage of all 586 BDD scenarios. Each package will be under 80KB (for efficient loading) and contain curated information so the agent can immediately enumerate all features in its domain. Key considerations include: balanced scenario distribution, minimal cross-domain overlap, and inclusion of verified implementation details.

**Scope of Repository Analysis:**

- **BDD Scenarios:** 586 scenarios spanning 42 feature files (`/specs/working/*.feature`) – these define the functional behaviors that must be verified.
- **UI Components:** 100+ React components in `src/components/` – the building blocks of the frontend (to identify which components each scenario touches).
- **API Endpoints:** ~147 REST endpoints defined under `src/api/routes/` – the backend operations that scenarios call (to map scenarios to API usage).
- **Database Schema:** ~761 database tables (as per verified schema) – underlying data structures (to catch scenarios that depend on certain data).
- **Deep Research Context:** Aggregated resources in `/deep-research-context/` including `registry_updated.json` (index of all scenarios with metadata), `verified-knowledge/` (confirmed components, APIs, DB tables, algorithms), and `r-agent-reports/` (findings from earlier agent runs, e.g. missing APIs).

**Primary Sources:** The **scenario registry** and **BDD feature files** are the ground truth for requirements, while the **verified knowledge base** confirms which components/APIs actually exist or are implemented. Earlier **R-agent reports** highlight gaps (e.g. hidden APIs, missing features) that the new domain packages must account for. By combining these sources, we ensure each domain package reflects both the specs and the current implementation reality.

## Domain Separation Analysis

We will re-partition the 586 scenarios into **8–10 logical domains**, optimizing for functional coherence and balanced load. All scenarios must be assigned to exactly one domain, with **no overlaps or gaps**. The criteria for domain separation include:

- **Business Function Clustering:** Group scenarios by related business areas or user roles (e.g. Employee Self-Service vs. Manager Admin vs. Scheduling). Scenarios in a domain should share a common functional theme.
- **Technical Component Reuse:** Aim for >85% of UI components and APIs used by scenarios to be *internal* to that domain. High internal reuse means an agent can load a set of components/APIs and see them used across most scenarios in that domain. This reduces context switching.
- **Minimal Cross-Domain Dependencies:** Keep scenarios together if they have strong interactions. Each domain should have <5% of scenarios needing coordination with another domain’s data or state (e.g. avoid one scenario in Domain A requiring a feature verified by Domain B). Prior guidance set a cross-domain dependency target under 10%, and we will push closer to 5% by careful grouping.
- **Balanced Workload:** Distribute scenarios such that each domain has roughly **60–75 scenarios**. This ensures each agent has a comparable amount of work and no single agent is overwhelmed. (Earlier analysis recommended ~40–60 scenarios per agent for 8 agents; with possibly 9–10 domains, 60–75 is achievable.) Balanced scenario counts also help keep each agent’s context usage predictable.

**Current Domain Assignment Issues:** Originally, eight “R-agents” were assigned domains, but with major imbalances and confusion:

- **R1-AdminSecurity:** ~72 scenarios covering admin settings and security.
- **R2-Employee:** ~68 scenarios on employee self-service features.
- **R3-Schedule:** **117** scenarios (far too many) covering all scheduling aspects, leading to context overload.
- **R4-Forecast:** ~73 scenarios on forecasting (reasonable size).
- **R5-Manager:** Only **15** scenarios (too few, under-utilized agent) focusing on manager approvals – likely incomplete grouping.
- **R6-Integration:** ~130 scenarios (extremely large) mixing integration, API, and advanced features – this domain must be split or it will exceed the token budget.
- **R7-Reports:** ~66 scenarios for reporting/analytics, but the agent misinterpreted its mission and only meaningfully covered ~25 scenarios (claimed “100%” but results were irrelevant to many specs). This indicates a domain definition problem and agent misunderstanding.
- **R8-Mobile:** ~24 scenarios on mobile app and notifications (very small domain, possibly could be expanded or merged).

These assignments were **problematic**: R3 and R6 were overloaded (117+ scenarios) while R5 and R8 were under-loaded, and some features (like an entire monitoring module) were not assigned to any agent at all. R7’s domain was poorly defined, causing the agent to verify the wrong things (it missed ~60% of its intended scenarios). Clearly, we must re-analyze all 586 scenarios from scratch to define optimal domains.

**Planned Domain Optimization:** We will likely maintain ~8 core domains but adjust boundaries (or go to 9–10 domains) to fix the imbalance. For example: the large Scheduling domain can be split into two domains (e.g. **Scheduling Operations** vs. **Advanced Scheduling Optimization**) so that each has ~60 scenarios. The overly broad Integration domain might be split into **System Integration** vs. **Advanced Features**. Conversely, very small domains (like Mobile) might be combined with related web features to reach a meaningful size (e.g. **Employee Self-Service** domain could include Mobile app scenarios). Each new domain will be given a clear name reflecting its functional scope (using consistent naming conventions as described below). We will verify that **all 586 scenarios are accounted for exactly once** in the new domain map, using a coverage matrix for validation.

Notably, prior deep research recommended an 8-domain structure as a starting point. We will validate that recommendation against our criteria; if 8 domains yield uneven distribution, we will consider 9 or 10 domains (as earlier analyses also contemplated). The end result will be a **Domain Separation Map** assigning every scenario ID to a domain, and a **Dependency Matrix** highlighting any remaining cross-domain touchpoints (expected to be minimal). This upfront analysis ensures each agent knows exactly which scenarios belong to them, with **natural affinity** within their set, and almost no overlapping responsibilities between agents.

## Domain Package Structure and Contents

For each defined domain, we will construct a **JSON-formatted knowledge package** (estimated 50–80 KB each) that includes everything the agent needs to know for that domain. The structure will be standardized across all domain packages for consistency. Key sections of each domain package include:

- **Domain Metadata:** The package will start with identifying info like the domain name (e.g. `"R3-SchedulingOperations"`) and a version number for the package schema. It also specifies the token budget breakdown (e.g. reserving ~50K for this package, ~100K for working memory, etc., summing to the 200K total).

- **Scenario Index:** A complete list of all scenarios assigned to this domain. Each entry will include the scenario’s unique ID, name (title), source feature file, and line number within that file. We will also include any priority or tag (e.g. demo-critical) and a **URL hint** if applicable (a clue for the agent about which part of the UI to navigate; for example, a scenario about schedule optimization might hint the URL `/scheduling/optimize`). This index essentially tells the agent **“Here are all the requirements you need to verify.”**

- **Navigation Map:** A guide to relevant application URLs and typical UI flows for this domain. This includes base URLs (e.g. the admin portal vs employee portal paths for this domain’s features) and key page routes. For example, a Scheduling domain might list base path `.../views/env/scheduling/` for the admin UI and `.../mobile/schedule/` for the employee UI. It will list **key pages** (with names and URLs, like “Schedule Grid – `/schedule/grid`”) and common **state sequences** (step-by-step navigation flows, such as “login → dashboard → scheduling module → create schedule”). This map gives the agent an overview of how to reach the features under test, so it doesn’t waste time searching the UI.

- **Components Registry:** A breakdown of UI components relevant to this domain, divided into three categories for clarity:

  - **`verified_exist`:** components that are confirmed to exist and function, based on our verified knowledge (e.g. from `verified-knowledge/components/`). These are likely already implemented and were identified by earlier verification or development.
  - **`found_in_codebase`:** components that were found in the source code (`/src/components/`) and seem relevant, but have not yet been verified in action. They exist in the code, so the agent may encounter them, but their behavior/status is uncertain.
  - **`should_exist`:** components that **should** exist according to BDD scenarios or design expectations but were **not found** in the code (i.e. potential gaps). These are essentially “missing features” flags for the agent: if a scenario references a UI element or component name that doesn’t map to any known code, it goes here.

  By clearly labeling components into these three buckets, the agent can prioritize its focus. Verified components can be trusted and quickly referenced; unverified ones might need testing or could be stubs; “should exist” items signal places to be extra vigilant (the agent might need to mark these scenarios as unimplemented or create them). For example, a SchedulingOptimization domain’s component registry might show `ScheduleView.tsx` and `ShiftGrid.tsx` under verified (✅ confirmed in prior work), an `OptimizationEngine.tsx` under found_in_codebase (exists in code, ❓ needs verification), and a `ScheduleOptimizer.tsx` under should_exist (❌ referenced in specs but no implementation yet).

- **API Registry:** Similarly, a list of REST API endpoints relevant to the domain, each annotated with method(s) and implementation status:

  - Endpoints that are **verified_working** (documented in `verified-knowledge/api/ALL_ENDPOINTS_DOCUMENTED.md` or tested OK) – the agent can use them confidently.
  - Endpoints that are **found_not_verified** – they appear in the code (`/api/routes/…`) but haven’t been fully tested or might be returning placeholder data. The agent should test these and be prepared for incomplete behavior.
  - Endpoints **missing** (expected by scenarios but not implemented) – the agent should recognize these as gaps; the scenario cannot be fully executed until these APIs are built. We will list which scenarios require those missing endpoints, to emphasize their importance.

  Each API entry may include a note or source reference. For instance, if `/api/v1/optimize` exists in code but not in the docs, we mark it **found_not_verified** and note that it might return mock data or require further implementation. If a scenario expects an endpoint like `/api/v1/schedules/ai-suggest` that doesn’t exist at all, it’s marked **missing** and tied to the specific scenario IDs that need it. This foreknowledge prevents the agent from spending tokens searching fruitlessly for an endpoint – it already knows it’s not there and can plan accordingly (e.g. flag it for development or simulate its response).

- **Cross-Domain Dependencies:** A small mapping of how this domain interacts with others, to anticipate any coordination needs:

  - **`needs_from`:** lists any data or functionality this domain’s scenarios require from other domains. For example, a Scheduling domain might need **employee availability** info (provided by the Employee domain) or **manager approval status** (from a Manager domain). We will list such dependencies by domain name and topic.
  - **`provides_to`:** conversely, what this domain provides to others. E.g., the Scheduling domain provides **schedule data** that the Reporting domain will use, or outputs a **personal schedule** that the Employee app will display.

  These cross-domain notes will be kept minimal (ideally nearly empty) thanks to our domain separation strategy. However, where they exist, they alert agents that a certain other agent might have to verify something first or share a result. Our target is to keep cross-talk <=5% of scenarios, but when it does happen, it will be clearly documented so agents can coordinate. (For example, if Domain A must create an entity that Domain B will then report on, Domain A’s agent can notify Domain B’s agent once done, rather than Domain B’s agent stumbling on a missing prerequisite.)

- **Known Patterns:** A list of any **design or integration patterns** known to recur in this domain’s scenarios. Through previous analyses, we identified at least 6 common integration patterns that cover ~80% of tricky cases (e.g., specific ways the UI and API sync state, or how certain calculations are repeated). If a domain’s scenarios frequently involve, say, **Pattern-1: URL route construction** or **Pattern-5: use of standardized test selectors**, we will list those. This primes the agent to apply known solutions or look out for known pitfalls. Patterns might also include known performance trade-offs (like “large schedule grids might require virtual scrolling – Pattern-6”) or typical UI conventions (like “date pickers always use a certain library – Pattern-3”). Essentially, this is the distilled wisdom from prior integration efforts that the agent should leverage instead of reinventing the wheel.

- **Previous Discoveries:** Any relevant findings from earlier agent runs or explorations that pertain to this domain. This can include:

  - **Hidden features uncovered:** e.g. “Discovered 12 schedule template types not documented in specs” – things an earlier agent or developer found that weren’t in the original requirements. We include these so the new agent doesn’t overlook them.
  - **Known blockers or pitfalls:** e.g. “Permission X is required to access the AI optimization feature” (which might have stymied an earlier attempt), or “Feature Y is behind a feature flag.” By listing these, the agent can proactively handle them (ensuring it has the right admin access, enabling flags, etc.).

By packing the domain package with all these sections, we ensure each agent has a **complete briefing** on its domain. The agent will know **which scenarios to cover, how to navigate to them, which UI components and APIs are involved (and their status), what dependencies to mind,** and even past lessons learned. This preloaded context should drastically cut down on redundant searches – agents won’t waste time searching for components or endpoints that we already know are missing or irrelevant. As noted, previous agents wasted 60–75% of their tokens on searching and reading code blindly. With these packages, we aim to convert that time into productive verification work.

*Example Snippet:* The structure below illustrates a simplified example for a Scheduling Optimization domain (for brevity, not all fields are expanded):

```json
{
  "domain": "R3-SchedulingOperations",
  "package_version": "1.0",
  "token_budget": { "total": 200000, "package_size": 50000, "working_space": 100000, "conversation": 50000 },
  "scenario_index": [
    {
      "id": "SPEC-24-001",
      "name": "AI-based schedule optimization",
      "file": "24-automatic-schedule-optimization.feature",
      "line": 45,
      "priority": "demo-critical",
      "url_hint": "/scheduling/optimize"
    },
    // ... ~60 more scenarios in this domain ...
  ],
  "navigation_map": {
    "base_urls": {
      "admin_portal": "/ccwfm/views/env/scheduling/",
      "employee_portal": "/mobile/schedule/"
    },
    "key_pages": [
      { "name": "Schedule Grid", "url": "/schedule/grid", "portal": "admin" },
      { "name": "Template Manager", "url": "/templates", "portal": "admin" }
    ],
    "state_sequences": [
      "login → dashboard → scheduling → create schedule",
      "login → templates → apply template → publish schedule"
    ]
  },
  "components": {
    "verified_exist": ["ScheduleView.tsx", "ShiftGrid.tsx"],
    "found_in_codebase": ["OptimizationEngine.tsx", "AIScheduler.tsx"],
    "should_exist": ["ScheduleOptimizer.tsx", "ConflictResolver.tsx"]
  },
  "api_registry": [
    { "endpoint": "/api/v1/schedules", "methods": ["GET","POST"], "status": "verified_working" },
    { "endpoint": "/api/v1/optimize", "methods": ["POST"], "status": "found_not_verified", "note": "Exists in code, returns placeholder" },
    { "endpoint": "/api/v1/schedules/ai-suggest", "methods": ["POST"], "status": "missing", "required_by": ["SPEC-24-001"] }
  ],
  "cross_domain_deps": {
    "needs_from": { "R5-Manager": ["employee_availability", "approval_status"] },
    "provides_to": { "R7-Reporting": ["schedule_data"] }
  },
  "known_patterns": [
    "Pattern-6: Performance vs. functionality trade-off for large data grids",
    "Pattern-7: Calendar integration expected for date selectors"
  ],
  "previous_discoveries": {
    "hidden_features": ["Gantt chart view for schedules exists but undocumented"],
    "blockers": ["Admin role required for AI optimization feature"]
  }
}
```

Each domain package JSON will be structured like the above, tailored to its content. We will keep each package under the 80 KB limit by limiting extraneous detail and possibly compressing parts of the text (e.g. scenario descriptions will not be fully in the index, just names/IDs to keep it concise). The scenario’s detailed steps can be loaded on-demand from the feature file when needed, rather than stored fully in the package.

## Common Knowledge Package (Shared Context)

In addition to the domain-specific packages, we will prepare a **Common Knowledge Package** for all agents to share. This will be a smaller JSON (target <30 KB) that contains global information about the WFM system and test environment that every agent should know. Rather than duplicating this context in each domain file, we keep it centralized. Key elements of the common package include:

- **Project Structure Overview:** A high-level map of the repository (like the key directories and their purposes). This helps agents understand where to find things (e.g. specs are in `/specs/working/`, API code in `/src/api/`, frontend in `/src/ui/`, etc.). It will also note naming conventions (for instance, feature files and scenario IDs use a specific numbering scheme, such as `NN-feature-name.feature` with scenarios labeled `SPEC-NN-XXX` in the registry). This ensures agents speak the same language when referencing files.

- **Authentication and Session Patterns:** Information about how to log in and persist sessions, since all test scenarios likely start with authentication. Notably, our target system is Argus-compatible, meaning the admin interface uses JSF (JavaServer Faces) with a view-state mechanism and the employee portal uses a separate Vue.js app with JWT authentication. The agents need to know:

  - The **Admin portal** (for management and configuration tasks) is a server-rendered JSF application embedded at `.../ccwfm/views/env/...` and might require handling view-state tokens on forms (a quirk of Argus’s legacy tech). Also, the UI labels are in Russian (since Argus is Russian-language), so test agents should expect Russian text in the UI.
  - The **Employee portal** (for employee self-service tasks) is a modern web app (Vue/React) accessible under `.../mobile/...` and uses an API with JWT tokens for authentication. The agents should use provided test credentials and capture the JWT to call APIs if needed.

  This common info ensures that, for example, the Security domain agent and the Employee domain agent both know how to perform a login (admin vs employee) and navigate initial screens without needing that in each domain file.

- **Global Navigation Structure:** An outline of the main menus or sections of the application. For instance: Dashboard, Employee Management, Scheduling, Forecasting, Reporting, System Administration, etc. This helps agents understand where their domain fits in the bigger picture. If an agent’s domain is “Reporting & Analytics”, it knows those features are under the “Reporting” section of the UI menu, which might only appear for users with certain roles. If the domain is “Integration”, it might not have a visible menu section but rather background services – that context can be explained here. We will also note any **global UI components** that appear everywhere (like top nav bars, footers, notifications) so agents don’t get distracted by them as if they were domain-specific.

- **Common UI Components and Utilities:** List of components or tools used across multiple domains. For example, a date-picker component, a table component, or a modal dialog might be used in many features (and thus show up in multiple domain packages). Instead of listing the same common component in every domain file, we can note them here. If all domains use `Login.tsx` or a `MainLayout.tsx`, we document it once. We also note standard design systems or libraries in use (perhaps a mention of “Using PrimeFaces for admin UI” or “Using Ant Design for React components”) so agents are aware of the general UI framework.

- **Coordination Protocols:** Guidelines for how agents should coordinate if a cross-domain dependency arises. Since we aim to minimize these, coordination should be rare, but we need a plan for when it happens. For example, if the **Scheduling** agent needs a new employee created (which is a scenario under the **Employee** domain), the protocol might be: “Agent R3 should request Agent R2 to create test data via a shared channel or by calling a setup API.” Or if an agent finds an undocumented API that belongs in another domain’s purview, it should log it in a common list for that agent. Essentially, we will outline how to handle inter-domain data sharing, sequencing (who goes first if one scenario depends on another’s outcome), and how to use the common knowledge store to leave notes or flags for each other. This prevents duplication of effort and ensures one agent’s discovery benefits all others (truly “collective intelligence” among the agents).

- **File Size and Token Guidelines:** Reminders of limits (since all agents share the same 200K token constraint). For example, instruct agents to always load the **small** index first (and not immediately the full 50KB context) until needed, to avoid blowing past 80% usage. Also, conventions like summarizing after finishing a scenario to free up memory. This is more about how to use the packages rather than domain knowledge, but it’s common instruction every agent should follow. We may include a note like: “Each agent should keep its working context under 160K tokens (~80%) to avoid hitting the 200K limit where the system becomes unstable.” The common package might list best practices for context management.

All agents will load this common package alongside their domain-specific package. By doing so, they share a unified understanding of the system’s foundation and rules. This prevents inconsistent interpretations (e.g., all know the login steps, all know where to find API docs, etc.). It also fosters synergy: e.g., if one agent updates the common knowledge (perhaps discovering a global issue, like a session timeout behavior), that info can propagate to others. The Common Knowledge Package is kept lean (<30KB) by focusing only on broad, cross-cutting information and not duplicating any scenario-specific details found in domain packages.

## Progressive Loading Strategy

Even with well-curated packages, we must manage how agents load context over a multi-hour session to avoid context exhaustion (the dreaded 200K token limit crash). We propose a **three-phase progressive loading** strategy for each agent’s session:

- **Phase 1: Index-Only Boot (Initial ~20KB load)** – When an agent starts, it will load only the lightweight parts of the packages:

  - The Common Knowledge Package (global info, ~20–25KB).
  - The **index portion** of its Domain Package, which includes just scenario IDs/names and perhaps priorities and URL hints (we can strip out heavy details initially). This index might be, say, 15–20KB for ~70 scenarios.

  In this phase, the agent’s context might be around 40KB (well under 25% of the limit). With this, the agent can **list out all scenarios** it needs to handle and plan its approach, without yet delving into details. It can prioritize which scenarios to attempt first (e.g., demo-critical ones get done early) and identify which ones might depend on others. The agent can also do quick checks like opening key pages from the navigation map to ensure it has access.

- **Phase 2: Full Context Load (On-demand ~50KB chunk)** – As the agent begins working on a particular scenario or set of scenarios, it will load the rest of the domain package details relevant to those scenarios:

  - For example, if it is about to verify a scheduling optimization scenario, it will load the component and API registry sections for Scheduling (if not already loaded) to get full context on those components/APIs. This might bring the total context up to ~70–80KB when needed.
  - It can also pull in the full BDD scenario text from the `.feature` file for the scenario it’s executing. A single scenario’s steps are usually short (maybe 0.5–1KB of text), so even a few scenarios loaded in detail won’t break the bank.

  In this phase, the agent operates with a **rich context (~70–120KB)** that includes the relevant domain knowledge plus the specifics of the scenarios at hand. Crucially, it won’t load all 70 scenarios’ details at once. It can load maybe 5–10 scenarios’ detailed steps at a time (particularly those it plans to test in this hour), complete them, summarize results, and then load the next batch. The domain package (50KB) remains available in context for reference, but only portions of it might be active at any given time if needed.

- **Phase 3: Dynamic Memory Management (Continuous during work)** – As the agent runs through scenarios over a 4+ hour session, it will practice good memory hygiene:

  - After completing a scenario or a logical group of scenarios, the agent will **summarize outcomes and then discard the detailed steps** of those scenarios from the context (keeping just a summary or marking them as done). This frees up token space. The domain package and indexes remain as reference, but the step-by-step narrative of a scenario can be dropped once verified.
  - If the agent needs to revisit a scenario, it can always reload it from the feature file quickly (since it knows exactly which file and line, thanks to the scenario index).
  - The agent should monitor that its context usage stays below ~80% (around 160K tokens) at all times. If it starts creeping up (e.g. due to chat conversation or large outputs), it should proactively summarize or trim less relevant parts of the context.
  - For any scenario that involves a complex multi-step workflow, the agent can load and verify in parts. For example, load steps 1–3, verify those, then maybe unload them and load steps 4–6 if needed, rather than holding the entire lengthy scenario in memory if not necessary.

This progressive loading ensures that the agent **never approaches the 200K token “death zone.”** In our current experience, agents that naïvely load tons of context up front often hit ~190K tokens and crash (the session becomes unresponsive) – we will avoid that by always keeping a buffer. By Phase 3 tactics (dynamic unloading and summarizing), an agent can run indefinitely (several hours) without memory issues, even as it processes dozens of scenarios.

**Phase-wise Content Summary:** To clarify the size and content at each phase:

- *Phase 1 (Initial)*: ~20KB from common + ~20KB domain index = ~40KB. Contains just scenario list, critical metadata, basic nav info.
- *Phase 2 (Working context)*: Adds full domain knowledge (~50KB) + detailed scenario text for current scenario(s) (~a few KB each). Context peaks around 80–100KB typically, leaving ample headroom.
- *Phase 3 (Ongoing)*: Recycles context by removing done items, keeps usage ~80% max. Only loads what’s needed next. The domain package content (like component and API lists) might stay loaded for reference, since it’s static ~50KB, and the other ~50–70KB is used flexibly for scenario details and conversation.

This strategy will be documented in a **Progressive Loading Strategy Guide** (likely a separate JSON or MD file) that all agents follow. It basically scripts out how to handle context so that even if an agent has 70 scenarios to test, it never tries to load 70 scenarios worth of detail all at once. We anticipate this will allow a sustained verification session of 4+ hours per agent with no memory crashes, even if the agent is very active. The result is consistent progress without interruptions.

## Coverage Verification Matrix

To ensure we truly cover **100% of the 586 scenarios** with our domain assignments, we will maintain a **Coverage Verification Matrix**. This is essentially a table listing each domain alongside key metrics to track coverage and balance. An initial outline of this matrix is as follows:

| **Domain (Agent)**          | **# Scenarios** | **UI Components** | **API Endpoints** | **Cross-Domain Deps**          | **Priority Focus**         |
| --------------------------- | --------------- | ----------------- | ----------------- | ------------------------------ | -------------------------- |
| **R1-SecurityAdmin**        | 72              | ~15               | ~25               | None                           | High (security-critical)   |
| **R2-EmployeeSelfService**  | 68              | ~20               | ~18               | Needs R5 for approvals         | Critical (user-facing)     |
| **R3-SchedulingOperations** | ~75             | ~30               | ~22               | Provides to R7, Needs R5       | Critical (core scheduling) |
| **R4-Forecasting**          | ~70             | ~18               | ~15               | None                           | High (analytics)           |
| **R5-ManagerWorkflows**     | ~60             | ~12               | ~10               | Provides to R3/R7              | Medium (approvals)         |
| **R6-SystemIntegration**    | ~65             | ~25               | ~20               | Soft link to all (integration) | Medium (infrastructure)    |
| **R7-ReportingAnalytics**   | ~60             | ~15               | ~12               | Needs data from R3/R2          | Medium (analysis)          |
| **R8-MobileNotifications**  | ~40             | ~10               | ~8                | Uses R2 data                   | Low (specialized)          |
| *Possible R9-AdvancedAI*    | *40–50*         | *10*              | *17*              | *None*                         | *High (innovative)*        |

*(Note: The numbers above are illustrative placeholders. Final counts will be adjusted once scenario re-mapping is done. For instance, if we end up with 9 domains, some counts will shift accordingly. The goal is that each domain has roughly 60–75 scenarios, except possibly a smaller one if truly needed for a distinct area like mobile.)*

In the matrix:

- **# Scenarios** is the count of scenarios assigned to that domain (to verify load balance). All these should sum to 586. We will ensure no scenario is missing (the matrix will highlight any count mismatch).
- **UI Components / API Endpoints** indicate how many unique components and APIs are involved in that domain’s scenarios (based on our registry data). This gives a sense of complexity. E.g., R3 might touch 30 different UI components, meaning it’s quite complex UI-wise. If one domain had an extremely high number of components relative to scenarios, that might signal it’s too broad and could be split.
- **Cross-Domain Deps** summarizes if the domain heavily depends on others. Ideally this column is “None” or very minimal. Any non-none entry here means we must have a plan (in the package and in coordination protocols) to handle that dependency.
- **Priority Focus** denotes if the domain carries many high-priority (Demo-critical) scenarios. We want high-priority scenarios spread out. For example, Security and Scheduling might both have critical scenarios (like login security, or schedule generation for the demo). We avoid concentrating all top-priority scenarios in one domain. Our matrix will check that the ~55 demo-critical scenarios (Value=5) are distributed across domains, not all in one.

The coverage matrix will be updated as we finalize domain assignments. It acts as a **verification checklist**: once domain agents start working, we can mark scenarios off in this matrix as they get verified. It also helps identify if any domain is lagging (say R8 has only 40 scenarios, maybe that agent finishes early, we could reassign some lower priority tasks to it if needed). In summary, this matrix is both a planning tool and a progress tracker to ensure **no scenario is left unverified** and no scenario is double-covered either.

## Implementation Instructions for Each Domain Agent

Alongside the packages, we will provide an **Agent Implementation Guide** detailing how each agent should use its domain package and proceed with verification. Key instructions to be included for each domain/agent:

- **Quick Start Setup:** Precisely how to start testing the domain. This includes any environment setup or credentials (e.g. “Use admin account for R1-SecurityAdmin, use employee test account for R2-EmployeeSelfService”). It will list any special commands or configs (for example, if there are specific NPM scripts or Python scripts to seed data for that domain’s features). Essentially a short “how to start” so the agent can begin immediately. For instance: *“R3 agent: run `npm run seed-schedules` to preload sample schedules, then navigate to the Schedule Grid page.”*

- **Verification Sequence & Best Practices:** Guidance on the order or method to tackle scenarios. We might suggest verifying scenarios in a logical order (perhaps sorted by feature file or by dependency). For example: “EmployeeSelfService agent: verify `employee-requests` scenarios first (they are independent), then do `shift-exchange-marketplace` scenarios which require existing shifts.” This sequence prevents the agent from hitting prerequisites issues out of order. Best practices might include reusing test data within a domain (e.g., create one test employee and reuse it for multiple scenarios if appropriate to save time). We will also remind them to utilize the navigation map for direct page access instead of clicking through the whole app every time.

- **Success Metrics per Agent:** Define what “done” looks like for the agent’s domain. This could be quantitative and qualitative:

  - All scenarios in the domain executed and passed (or if failing due to bugs, those are documented for fixes).
  - All domain APIs have been hit/tested at least once, and all UI components have been rendered or inspected.
  - For example: “R1-SecurityAdmin success = 72/72 scenarios passed, including all security test cases (password rules, role permissions etc.), with zero critical bugs open.” We might set targets like at least 15 scenarios verified per day per agent, to finish in ~4 days. The guide will list such targets so agents can self-assess performance.

- **Summarization Template:** A standardized format for the agent to log their results and findings after each scenario or at end-of-day. This template ensures consistency in what data is captured:

  - Scenario ID, Title, Status (Pass/Fail/Blocked).
  - Notes on implementation (e.g., “API returned 500, bug logged as #123”), or “Feature not implemented, flagged for dev.”
  - New discoveries (like if the agent found an undocumented API or a hidden component).
  - Time taken or complexity notes if relevant.

  By following a template, it will be easier to aggregate reports from all agents and update the central knowledge bases (like updating the verified knowledge docs with newly verified components or marking scenarios as completed). We will include this template and an example filled-out entry in the guide so each agent adheres to it.

- **Handoff and Escalation Protocol:** Instructions for what the agent should do if it encounters something outside its domain. For instance:

  - If an agent finds a scenario that actually belongs to another domain (perhaps a mis-categorization), it should stop and flag it to the program lead or the other domain’s agent rather than continue blindly.
  - If an agent hits a blocker because another domain’s functionality isn’t ready (e.g., the Reporting agent can’t test a report because the Scheduling agent hasn’t created any schedules yet), how to coordinate that. Possibly a shared channel or a daily sync where agents quickly exchange “I need X data” or “I have finished Y so you can proceed.”
  - If an agent discovers a missing piece (like a new API that’s not in any package), there should be a process to update the relevant package (or at least note it centrally) so we keep our knowledge up to date. We might instruct agents to update a `discovery_log.md` or the common knowledge package with such finds.

  Essentially, while each agent works mostly independently within its domain, these guidelines ensure if any inter-dependency or surprise arises, it’s handled smoothly without duplication or confusion. The end result should be **zero duplicate work between agents** – e.g., no two agents unknowingly test the same scenario or same API, and no agent wastes time on something another agent already found and documented.

These implementation instructions will likely be compiled into an **AGENT_IMPLEMENTATION_GUIDE.md** or similar, and a brief section might also be present in each domain package file summarizing “how to use this package.” The instructions are crucial to translate the static domain packages into effective action on the ground. With them, even if a new team member (or AI agent) comes on board, they can quickly understand how to proceed within the defined framework.

## Additional Critical Context and Rationale

### The 25% Discovery Problem

The impetus for this initiative comes from observed shortcomings in our initial verification attempts. Agents without domain guidance were **missing 60–75% of features** on average:

- **Agent R7 (Reporting):** Out of 86 reporting-related scenarios, R7 only meaningfully verified ~25 before running out of context or diverging into irrelevant areas. Yet it mistakenly reported 100% coverage, showing it didn’t even realize it missed things – a clear sign it lacked a complete scenario list for reference.
- **Agent R1 (Security):** This agent stumbled upon 25+ API endpoints that were not documented anywhere – essentially by accident. These were security APIs that existed in code but not in specs. Without prior knowledge, the agent spent huge effort just finding these. A domain package would have listed them upfront (with status), saving that time.
- **Agent R0 (Exploratory):** Discovered that an entire **Monitoring module** was absent from the specs (no BDD scenarios at all) even though it existed in Argus. This means the initial scenarios were incomplete. We now suspect **40–60% of actual system features were “hidden”** (either not documented in BDD or only implied). This aligns with a metric from GPT-Agent’s analysis indicating only ~35% of the legacy system’s capabilities had been captured in our specs. Such hidden features would have gone completely unchecked if agents only followed the written scenarios blindly.

These examples underscore why an informed approach is needed. By compiling comprehensive domain packages (with scenario indexes and references to hidden or extra features), we essentially ensure **no feature goes unaccounted for.** The agent will have a checklist of everything in its domain, including things that previous specs or documentation might have missed, because we’re aggregating knowledge from multiple sources (specs, code, prior discoveries).

Moreover, when an agent knows something is missing (e.g. an entire module like Monitoring has no scenarios), it can flag that explicitly rather than just never testing it. The domain packages can include such hints (for instance, a “discovery_hints” section listing likely features to check even if not in BDD). In short, we turn the unknown unknowns into known unknowns that the agents can then address methodically.

### Hidden Features and Gaps

Our preparation will involve combing through the codebase and Argus documentation to identify features that lack scenarios. We have already added notes in some domain drafts about potential hidden features:

- For Scheduling: e.g., a **shift marketplace** (“Биржа смен”) feature was noticed by R5 even though not fully specified. We would include that in whatever domain covers shift swapping, so the agent knows to verify it.
- For Notifications: push notification handling and PWA offline support might be present (in Mobile domain) but not documented – include hints for agent to test push subscription flows.
- For Security: any admin security settings (like password policies, IP whitelisting) that weren’t in BDD but exist in Argus should be listed so R1 checks them.
- Etc.

In the domain packages, these will appear either as extra scenarios we’ve added to the index (if we create proxy scenarios for them) or as notes under “previous_discoveries” or “should_exist” components/APIs. Essentially, no significant feature from the Argus baseline should be missed just because our BDD specs overlooked it. The goal is a **complete feature map** per domain.

### Argus System Integration

Our WFM system is meant to fully replace Argus CCWFM, and part of verification is ensuring parity with Argus. Agents will be using the actual Argus environment (at least for reference or cross-checking behaviors) as mentioned:

- The Argus system’s **Admin portal** is at `https://cc1010wfmcc.argustelecom.ru/ccwfm/` (with a path structure under `/views/env/...` for different modules) – all in Russian. Agents must be cognizant of language (test steps may involve Russian labels or data). The view-state mechanism of Argus means certain actions (like form submissions) behave differently from our React frontend; this might affect how we simulate them. We’ll capture these nuances in the common knowledge (e.g. “In Argus, clicking ‘Save’ triggers a form post with a hidden state key; our system uses an AJAX call instead.”) This helps agents understand differences in behavior when comparing outcomes.
- Argus’s **Employee portal** is a separate web UI (which we believe is a Vue or similar SPA). It likely has different endpoints (maybe Argus has an older API for mobile). Our system consolidates some of that, but the agent should know to test both the web UI and mobile flows if applicable. For example, time-off requests might be doable from both the web and mobile; the domain agent covering Employee Self-Service should verify both interfaces if needed.

Including Argus context ensures that agents are not just testing in a vacuum – they know what the expected behavior or feature set is by comparing to the baseline. Any major discrepancy (like Argus had X feature, our system doesn’t) will be caught, which is crucial for achieving our parity goals.

### Expected Outcomes and Benefits

Implementing these Informed Agent Domain Packages is expected to dramatically improve verification outcomes:

- **Near-Complete Feature Discovery:** Agents should now discover >95% of the scenarios and features in their domain, a huge jump from the current 25–40% discovery rate. They’ll be explicitly aware of all 586 scenarios (divided among them) from the start. There will be no excuse for missing a scenario because it wasn’t known – it’s in their index. We anticipate essentially closing the gap so that hidden features are either found or at least flagged intentionally (no unexamined dark corners).
- **Efficient Context Utilization:** By pre-structuring context and using progressive loading, each agent will keep their context usage under ~80% throughout their session, avoiding memory crashes. Where previously agents wasted enormous tokens on aimless code search, now most tokens go to actual verification and reasoning. The domain packages (50KB) are heavy with information but *replace* what an agent might otherwise spend tens of thousands of tokens searching for on its own. This efficiency should enable longer continuous sessions (4+ hours of work) without hitting token limits or needing resets.
- **Elimination of Duplicate Work:** With clearly defined domain boundaries and an upfront assignment of scenarios, no two agents will be covering the same scenario or testing the same component unknowingly. For example, if an API belongs to domain R1, only R1’s agent will test it – others won’t waste time on it. The cross-domain dependency notes also prevent duplicate setup (e.g., only one domain will create a test data and others will reuse it). This specialization should accelerate overall progress (each agent focuses solely on its domain’s tasks).
- **Faster Mapping of System:** We estimate that with 8–10 focused agents, we can achieve complete API and component mapping in about **2 weeks**, whereas previously a single agent wandering across domains might have taken 4–6 weeks and still not map everything. The packages essentially parallelize the effort efficiently. Each agent can tackle ~15–20 scenarios per day (based on experience and the fact they have guidance). With ~586 scenarios total, even 8 agents at 15/day would cover 120 scenarios/day; in 5 days that’s 600 scenarios – alignment with our 4-day target plus a buffer for complex cases. The domain approach also inherently creates documentation as they go (each agent’s results update the package/knowledge base for that domain).
- **Improved Quality of Verification:** Agents armed with context will not only find more features but also verify them more thoroughly. They can follow known patterns and avoid false positives (e.g., R7 won’t report success just because it tested something irrelevant – it will have the exact list of what to test). The outcome should be that by the end, we have a **complete list of which scenarios pass, which fail, and why**, with virtually no scenario overlooked. This gives management and developers a clear picture of system parity vs. requirements.

**Success Metrics:** We will measure success of this approach by several concrete indicators:

- **Scenario Coverage:** Each agent should enumerate all scenarios in their domain at session start (proving they know their scope). Ultimately, 100% of the 586 scenarios should be either passed or reported as issues – none unknown or unaddressed.
- **Context Stability:** Agents should run 4+ hours without hitting context limits or needing a reset. If an agent consistently stays <80% token usage, that’s a win. No session terminations due to out-of-memory.
- **Coordination Overhead:** Cross-domain interactions should consume <5% of the agents’ effort and conversation. We can track how often agents have to communicate with each other or wait – it should be minimal thanks to our domain design. Ideally, an agent might only need to coordinate once or twice (if at all) during its run.
- **Daily Throughput:** Aim for each agent to verify ~20 scenarios per day (since they’re guided, some simple scenarios can go very fast). At minimum 15/day to meet our timeline. If an agent is falling short, we analyze if the package was lacking or if the agent needed more training.
- **Findings and Bug Reports:** As a positive side effect, we expect an increase in meaningful bug findings (since more hidden features are tested). But importantly, no critical feature should remain untested/unreported.
- **No Duplicated Bugs:** If two agents report the same bug, that indicates an overlap in testing – our domain split should prevent that (each bug/feature area should clearly map to one domain). We will monitor bug report logs to ensure there's no double-reporting of the same issue by different domains.

If all goes to plan, by the end of the exercise we will have a set of domain knowledge packages that not only guided the agents to success but also can be archived as documentation. They effectively become a **living specification** of the system, broken down by domain, with verified status of each component and endpoint. Future agents or developers can use them to quickly understand system coverage. This approach essentially operationalizes the idea of *“Know WHAT before exploring HOW”* – giving our AI agents the blueprint so they can focus their effort on validating execution.

## Conclusion

The creation of Informed Agent Domain Packages marks a strategic shift in how we approach system verification. By investing effort upfront in analysis and packaging knowledge, we enable our agents to perform at a much higher level, systematically covering the entire WFM system. This method addresses past failures (where agents were blind and inefficient) and leverages the full breadth of data we have – from BDD specs to code internals and prior findings – to guide the verification process.

Once these packages and protocols are in place, our 8–10 specialized agents will work in parallel like a well-coordinated team, each with clear marching orders and context. We expect to see near-complete coverage of scenarios, faster discovery of gaps, and a robust mapping between requirements and implementation. The end result will be a verified WFM system that we can confidently say matches (or exceeds) the legacy Argus capabilities in every aspect, achieved in a fraction of the time that ad-hoc exploration would have taken.

The approach is practical and immediately usable: we have identified the repository sections to draw from, outlined the JSON structures, and set concrete deliverables (domain files, common file, loading strategy doc, coverage matrix, etc.). As next steps, we will proceed to: (1) finalize the domain separation (assign each of the 586 scenarios to a domain and list them), (2) compile each domain package JSON with all relevant content, (3) write the Common Knowledge and Progressive Loading documents, and (4) review the packages to ensure size compliance and completeness. With that in hand, our agents can be booted up with this knowledge base and begin high-efficiency verification. We anticipate a transformative improvement in coverage and insight once this plan is executed, turning the current 25% feature visibility into virtually 100% clarity for our AI agents – and by extension, for our development team and stakeholders.

**Sources:**

- WFM BDD Scenario Analysis – 586 scenarios across the system
- Prior Deep Research on Domain Clustering and R-agent strategy
- WFM Repository Documentation (Project structure and stats)
- Deep Research Optimized Domain Assignment example (Employee Self-Service domain)
- BDD Implementation Reality Check (progress and scenario counts by category)