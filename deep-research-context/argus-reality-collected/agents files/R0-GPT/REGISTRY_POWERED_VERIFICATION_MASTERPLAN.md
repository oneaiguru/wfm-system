# 🚀 Registry-Powered Verification Master Plan & Handoff

**Agent**: GPT-AGENT (Reality Verifier)  
**Created**: 2025-07-26  
**Purpose**: Transform verification from 32 specs to 586 scenarios using registry system

## 📊 Current State Summary

### What We've Done (Old Way)
- Verified 32 feature files manually
- Average 35% system parity
- Took ~8 hours reading 300+ line files
- Found key patterns but inefficient discovery

### What Changes (Registry Way)
- 586 scenarios indexed and searchable
- Query-based discovery (10x faster)
- Automated progress tracking
- Pattern matching at scale

## 🎯 Registry-Powered Verification Workflow

### Phase 1: Session Initialization (5 minutes)
```bash
# 1. Navigate to registry
cd /agents/ORCHESTRATOR-ARCHITECT/BDD_SPEC_REGISTRY

# 2. Check current state
cat reports/demo_priority_status.md | head -20
cat reports/coverage_report.md | grep "Demo Value 5"

# 3. Find my previous work
jq '.scenarios[] | select(.verified_by == "GPT-AGENT")' registry.json | wc -l

# 4. Query next high-priority batch
jq '.scenarios[] | select(.demo_value == 5 and .status == "pending") | {name, file, line_start}' registry.json | head -20
```

### Phase 2: Smart Batch Selection (10 minutes)
```bash
# Strategy 1: By Feature (Context Clustering)
grep "09-work-schedule" registry.json | jq 'select(.status == "pending") | {spec: .spec_id, name: .name, line: .line_start}'

# Strategy 2: By Integration Pattern
jq '.scenarios[] | select(.tags | contains(["@integration"]) and .status == "pending" and .demo_value >= 4)' registry.json

# Strategy 3: Quick Wins (< 20 lines)
jq '.scenarios[] | select(.line_count < 20 and .status == "pending" and .demo_value >= 3)' registry.json

# Select 5-6 scenarios from same feature for context efficiency
```

### Phase 3: Targeted Verification (30 minutes per scenario)
```bash
# 1. Read ONLY the specific scenario
Read("/project/specs/working/[file]", offset=[line_start], limit=[line_count])

# 2. Navigate with correct MCP
mcp__playwright-official__ for localhost
mcp__playwright-human-behavior__ for Argus (if needed)

# 3. Document findings in feature file
Edit(file, old_string="Scenario: [name]", new_string="# VERIFIED: 2025-07-26 - [findings]\n# PARITY: X%\n@verified @[tags]\nScenario: [name]")

# 4. Create analysis if major gaps found
Write("/agents/GPT-AGENT/analysis/[feature]-[scenario]-analysis.md", findings)
```

### Phase 4: Registry Synchronization (5 minutes)
```bash
# 1. Sync changes
python3 sync_registry.py

# 2. Verify update
grep "[scenario_name]" registry.json | jq '.status'

# 3. Check progress
cat reports/coverage_report.md | grep -A5 "GPT-AGENT"
```

## 📚 Dynamic Reading List 3.0

### Core Files (Always Load)
```bash
# Session start essentials
/agents/GPT-AGENT/CLAUDE.md
/agents/GPT-AGENT/MCP_TOOL_USAGE_GUIDE.md
/agents/ORCHESTRATOR-ARCHITECT/BDD_SPEC_REGISTRY/registry.json
/agents/ORCHESTRATOR-ARCHITECT/BDD_SPEC_REGISTRY/reports/demo_priority_status.md
```

### Conditional Reads (Query-Triggered)
```bash
# IF demo_value == 5:
/agents/BDD-SCENARIO-AGENT-2/VACATION_JOURNEY_COMPLETE.md
/agents/BDD-SCENARIO-AGENT-2/MANAGER_JOURNEY_INTEGRATION_ANALYSIS.md

# IF tags contain "@integration":
/agents/BDD-SCENARIO-AGENT-2/INTEGRATION_PATTERNS_LIBRARY_UPDATED.md

# IF feature == "mobile":
/agents/BDD-SCENARIO-AGENT-2/MOBILE_JOURNEY_IMPLEMENTATION_HANDOFF.md

# IF status == "blocked":
/agents/AGENT_MESSAGES/FROM_*_UNBLOCKED.md
```

### Auto-Remove Protocol
- Remove handoffs > 3 sessions old
- Remove completed batch assignments
- Archive analysis files after registry sync

## 🔧 Registry Command Cookbook

### Essential Daily Queries
```bash
# Morning Status Check
echo "=== My Progress ===" && \
jq '.scenarios[] | select(.verified_by == "GPT-AGENT") | .status' registry.json | sort | uniq -c && \
echo "=== Demo Priority Remaining ===" && \
jq '.scenarios[] | select(.demo_value == 5 and .status == "pending") | .file' registry.json | sort | uniq -c

# Find Next Work
jq '.scenarios[] | select(.demo_value == 5 and .status == "pending") | {spec: .spec_id, name: .name, file: .file, line: .line_start}' registry.json | head -10

# Check Feature Completion
feature="09-work-schedule" && \
echo "=== $feature Status ===" && \
grep "$feature" registry.json | jq '.status' | sort | uniq -c

# Integration Gap Finder
jq '.scenarios[] | select(.tags | contains(["@integration"]) and .status != "verified" and .demo_value >= 4) | {name, file, integration_points}' registry.json

# Pattern Matcher
pattern="approval" && \
grep -i "$pattern" registry.json | jq 'select(.status == "pending") | {name, file, line_start}'
```

### Advanced Queries
```bash
# Multi-Agent Coordination
jq '.scenarios[] | group_by(.assigned_to) | map({agent: .[0].assigned_to, count: length, verified: [.[] | select(.status == "verified")] | length})'

# Blocker Analysis
jq '.scenarios[] | select(.tags | contains(["@blocked"])) | {name, file, blocker_reason}'

# Time Estimation
jq '.scenarios[] | select(.demo_value >= 4 and .status == "pending") | .line_count' | awk '{sum+=$1} END {print "Lines to verify:", sum, "Est hours:", sum/100}'
```

## 🤖 Verification State Machine

### State Transitions
```
PENDING → VERIFYING → VERIFIED/BLOCKED/PARTIAL

1. PENDING (Registry State)
   - Query: Find scenario
   - Action: Claim assignment
   - Tool: jq select

2. VERIFYING (Active Work)
   - Read: Specific lines only
   - Navigate: Correct MCP server
   - Test: Actual functionality
   - Document: Console logs, errors

3. VERIFIED (Complete)
   - Tag: @verified + patterns
   - Parity: Calculate %
   - Sync: Update registry
   - Report: Add to analysis/

4. BLOCKED (Can't Proceed)
   - Tag: @blocked
   - Document: Exact error
   - Message: Create handoff
   - Assign: To fixing agent

5. PARTIAL (Some Working)
   - Tag: @partial-implementation
   - Detail: What works/doesn't
   - Priority: Quick fix potential
```

## 📈 Progress Visualization Queries

### Dashboard Queries
```bash
# Overall Progress
echo "=== System Verification Progress ===" && \
jq '.scenarios[] | .status' registry.json | sort | uniq -c && \
echo "=== By Demo Value ===" && \
jq '.scenarios[] | group_by(.demo_value) | map({value: .[0].demo_value, total: length, verified: [.[] | select(.status == "verified")] | length, percent: (([.[] | select(.status == "verified")] | length) * 100 / length)})'

# Agent Leaderboard
jq '.scenarios[] | select(.verified_by != null) | group_by(.verified_by) | map({agent: .[0].verified_by, scenarios: length}) | sort_by(.scenarios) | reverse'

# Daily Velocity
today=$(date +%Y-%m-%d) && \
jq ".scenarios[] | select(.verified_date == \"$today\")" registry.json | wc -l
```

## 🚨 Anti-Patterns to Avoid

### ❌ DON'T
- Open feature files to browse
- Read entire 300+ line files
- Verify without registry query
- Forget to sync after edits
- Use grep on feature files
- Work on low demo value items

### ✅ DO
- Query registry first
- Read exact line ranges
- Batch by feature context
- Sync after each scenario
- Use jq for everything
- Focus on Demo Value 5

## 💡 Knowledge Graph Integration

### Pattern Discovery Flow
```
Registry Query → Navigate → Find Pattern → Document → Tag → Sync

Example:
1. Query: jq '.scenarios[] | select(.name | contains("approval"))'
2. Navigate: Find all need manager routes
3. Pattern: "Missing /manager/* routes"
4. Document: Add to INTEGRATION_PATTERNS
5. Tag: @missing-route @pattern-4
6. Sync: Updates all similar scenarios
```

### Cross-Reference System
```bash
# Find all scenarios with same pattern
pattern="@pattern-4" && \
jq ".scenarios[] | select(.tags | contains([\"$pattern\"]))" registry.json

# Find all scenarios with same error
error="404" && \
grep -i "$error" registry.json | jq '.name'
```

## 🎯 Session Handoff Template

### Quick Start Next Session
```bash
#!/bin/bash
# Copy-paste this block to start

cd /agents/ORCHESTRATOR-ARCHITECT/BDD_SPEC_REGISTRY

echo "=== Session Status ===" 
date
echo "Last sync:" && stat -f "%Sm" registry.json
echo "My progress:" && jq '.scenarios[] | select(.verified_by == "GPT-AGENT")' registry.json | wc -l
echo "Demo 5 remaining:" && jq '.scenarios[] | select(.demo_value == 5 and .status == "pending")' registry.json | wc -l

echo -e "\n=== Next High-Priority Batch ==="
jq '.scenarios[] | select(.demo_value == 5 and .status == "pending") | {spec: .spec_id, name: .name, file: .file, line: .line_start}' registry.json | head -10

echo -e "\n=== Recent Blockers ==="
jq '.scenarios[] | select(.tags | contains(["@blocked"]) and .verified_date >= "2025-07-25")' registry.json
```

### Session Metrics
- Scenarios verified this session: Run after sync
- Demo Value 5 progress: Check coverage_report.md
- Patterns discovered: Count @pattern-* tags added
- Blockers found: Count @blocked tags added

### Critical Context for Next Session
- All manager routes need UI implementation
- Profile service JavaScript error persists
- CORS configuration blocking integrations
- Mobile features surprisingly complete (PWA approach)
- Bilingual support is exceptional (70% parity)

## 🔄 Continuous Improvement Loop

### After Each Batch
1. What query would have found this faster?
2. What pattern appeared multiple times?
3. What reading was unnecessary?
4. What automation opportunity exists?

### Update These
- Registry queries collection (this file)
- Pattern library
- MCP usage guide
- Quick fix recommendations

## 🎉 The Power of Registry

### Before Registry
- 32 files verified in 8 hours
- Read ~10,000 lines
- Found patterns by accident
- No progress visibility

### With Registry
- 586 scenarios queryable
- Read only what's needed (~50 lines per scenario)
- Pattern matching at scale
- Real-time progress tracking
- 10x efficiency gain

### Final Command
```bash
# The most important query - what's the highest impact work remaining?
jq '.scenarios[] | select(.demo_value == 5 and .status == "pending" and .tags | contains(["@baseline"])) | {impact: (.demo_value * .business_value), name, file, quick_fix: .estimated_hours}' registry.json | sort_by(.impact) | reverse | head -5
```

---

**Remember**: The registry is your map, jq is your compass, and focused verification is your path to 100% coverage!