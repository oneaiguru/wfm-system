# BDD Verification Approach Documentation

## Overview
This document outlines the systematic approach for verifying and updating BDD specifications based on comparing our WFM implementation with the Argus WFM system.

## Key Reference Files

### 1. Exploration Instructions
- **File**: `/Users/m/Documents/wfm/main/agents/EXPLORATION_INSTRUCTIONS_FOR_AGENT.md`
- **Purpose**: Comprehensive guide for system exploration
- **Key Points**:
  - Focus on functional parity, not visual design
  - Use different MCP tools for different systems
  - Document business logic, not UI appearance

### 2. UI Component Mapping
- **File**: `/Users/m/Documents/wfm/main/agents/BDD-UI-PRIORITIZATION/BDD_UI_MAPPING.md`
- **Purpose**: Maps 580 BDD scenarios to UI components
- **Key Info**:
  - Prioritized by Demo Value (1-5)
  - Identifies existing vs missing components
  - Time estimates for implementation

### 3. Integration Patterns Library
- **File**: `/Users/m/Documents/wfm/main/agents/BDD-SCENARIO-AGENT-2/INTEGRATION_PATTERNS_LIBRARY_UPDATED.md`
- **Purpose**: Reusable solutions for common integration issues
- **Patterns**:
  - Pattern 1: Route Granularity Mismatch
  - Pattern 2: Form Field Accessibility
  - Pattern 3: API Path Construction
  - Pattern 4: Role-Based Route Confusion
  - Pattern 5: Test ID Missing for E2E
  - Pattern 6: Performance vs Functionality Balance

### 4. Journey Analysis Examples
- **Vacation Journey**: `/agents/BDD-SCENARIO-AGENT-2/VACATION_JOURNEY_COMPLETE.md`
- **Manager Journey**: `/agents/BDD-SCENARIO-AGENT-2/MANAGER_JOURNEY_INTEGRATION_ANALYSIS.md`
- **Purpose**: Detailed integration gap analysis with specific fixes

## Verification Process

### Step 1: Task Creation
Create individual task files in `/agents/BDD-VERIFICATION/available-tasks/` with:
- BDD spec reference (file path and line numbers)
- Systems to test (URLs and credentials)
- MCP tool usage instructions
- Expected outcomes
- Success criteria

### Step 2: MCP Tool Usage
**CRITICAL**: Use correct MCP server names
- For Argus (Russian sites): `mcp__playwright-human-behavior__`
- For localhost: `mcp__playwright-official__`

**Note**: The human-behavior MCP handles anti-bot measures and provides realistic browsing patterns.

### Step 3: Analysis Documentation
For each verified feature, create analysis in `/agents/ARGUS_COMPARISON/analysis/`:
```markdown
# [Feature] Analysis

## BDD Spec Review
- What the spec says (line references)

## Actual Implementation
- What our system does
- What Argus does (if accessible)

## Gaps Identified
- Missing functionality
- Different business logic
- Terminology differences

## Spec Updates Required
- Specific line updates
- New scenarios to add
- Obsolete scenarios to remove
```

### Step 4: BDD Spec Updates
Update specs in `/project/specs/working/` with verification comments:
```gherkin
# VERIFIED: 2025-07-25 - [What was verified]
# UPDATED: 2025-07-25 - [What was changed]
# TODO: [What still needs work]
# NEW: 2025-07-25 - [New scenarios added]
```

## Current Progress

### Completed Tasks
1. ✅ Created directory structure
2. ✅ Analyzed login functionality (01-system-architecture.feature)
3. ✅ Analyzed vacation requests (02-employee-requests.feature)
4. ✅ Created task templates for systematic verification

### Analysis Files Created
- `/agents/ARGUS_COMPARISON/analysis/01-login-verification.md`
- `/agents/ARGUS_COMPARISON/analysis/02-vacation-request-analysis.md`
- `/agents/ARGUS_COMPARISON/EXECUTIVE_SUMMARY.md`

### Discovered Issues
1. **Argus Access**: 403 Forbidden on admin/employee portals
2. **MCP Availability**: playwright-human-behavior not available in some environments
3. **Solution**: Focus on comparing our implementation against BDD specs

## Best Practices

### 1. Narrow Scope Per Task
- One BDD scenario or tightly grouped scenarios per task
- Prevents token exhaustion
- Enables focused analysis

### 2. Apply Integration Patterns
- Check patterns library for known issues
- Apply proven solutions consistently
- Document new patterns discovered

### 3. Prioritize by Demo Value
- Focus on Demo Value 5 features first
- These have highest business impact
- Reference BDD_UI_MAPPING.md for priorities

### 4. Session Continuity
- Regular task status updates in TodoWrite
- Archive completed tasks
- Leave clear breadcrumbs for session compaction

## Next Steps

1. **Continue Verification**: Work through remaining high-priority specs
2. **Deploy Sub-Agents**: For complex features, use focused sub-agents
3. **Update Specs**: Apply verification comments systematically
4. **Track Progress**: Update functional parity percentages

## Sub-Agent Strategy

For comprehensive coverage of 580+ BDD scenarios:
- Deploy multiple narrowly-scoped sub-agents
- Each owns 1-2 specific features
- Reference this approach document
- Use task files as agent instructions

Example sub-agent scopes:
- APPROVAL-WORKFLOW-AGENT (02-employee-requests lines 48-66)
- CALENDAR-VIEWS-AGENT (14-mobile-personal-cabinet lines 42-77)
- MULTI-SITE-SYNC-AGENT (01-system-architecture lines 52-86)

## Files to Reference
- BDD Specs: `/project/specs/working/*.feature`
- Our Implementation: `/project/src/`
- Task Templates: `/agents/BDD-VERIFICATION/available-tasks/`
- Analysis Results: `/agents/ARGUS_COMPARISON/analysis/`