# Verification Approach

## Step 0: Check Critical References
- UI Mapping: `/agents/BDD-UI-PRIORITIZATION/BDD_UI_MAPPING.md` (Demo Value scores)
- Patterns: `/agents/BDD-SCENARIO-AGENT-2/INTEGRATION_PATTERNS_LIBRARY_UPDATED.md`
- Journey Examples: `/agents/BDD-SCENARIO-AGENT-2/*_JOURNEY_*.md`

## Step 1: Read BDD Spec
```bash
Read /project/specs/working/[spec-file].feature
Focus on: Scenario descriptions, expected behavior
```

## Step 2: Find Our Implementation
```bash
Grep /project/src/ui/src/components for related terms
Read relevant components
Check if functionality exists
```

## Step 3: Create Analysis
```markdown
# [Feature] Analysis
## BDD Spec Says
- Line X: [requirement]
## We Have
- ✅ [what works]
- ❌ [what's missing]
## Parity: X%
```

## Step 4: Update BDD Spec
```gherkin
# VERIFIED: 2025-07-25 - [what was checked]
# TODO: [what's missing]
# UPDATED: [what changed]
```

## Key Questions
1. Does the functionality exist?
2. Does it work the same way?
3. What terminology differs?
4. What's the complexity gap?

## Output Files
- Analysis: `/agents/ARGUS_COMPARISON/analysis/[feature]-analysis.md`
- Updated spec: Add comments to `.feature` file