# Deep Research Request: Monorepo Migration Analysis

## Context
We have the ideal monorepo architecture (your previous analysis). Now we need to analyze our ACTUAL repository structure and create a migration plan.

## Current Repository Structure to Analyze

### ✅ ANALYZE THESE DIRECTORIES:

1. **Agent Structure** (Already R1-R8 organized!):
   - `/agents/R1-AdminSecurity/`
   - `/agents/R2-Employee/`
   - `/agents/R3-Schedule/`
   - `/agents/R4-Forecast/`
   - `/agents/R5-Manager/`
   - `/agents/R6-Integration/`
   - `/agents/R7-Reports/`
   - `/agents/R8-Mobile/`

2. **BDD Specifications**:
   - `/project/specs/working/*.feature` (42 files, 586 scenarios)

3. **Real Argus Findings**:
   - `/intelligence/argus/html files of real ui/`
   - `/intelligence/argus/docs-consolidated/`
   
4. **Knowledge Bases**:
   - `/agents/KNOWLEDGE/API_PATTERNS/` (Real JSF patterns)
   - `/agents/KNOWLEDGE/ARCHITECTURE/`

5. **Implementation Code**:
   - `/project/src/` (Our React/FastAPI implementation)
   - `/project/e2e-tests/`

### ❌ IGNORE THESE DIRECTORIES:
- `/agents/KNOWLEDGE/API/` (Our implementation, not Argus)
- Any `.git/` directories
- Any `node_modules/` directories
- Media files and binaries

## Specific Analysis Required

### 1. BDD Scenario Mapping
Analyze all 42 feature files in `/project/specs/working/` and:
- Map each to appropriate R1-R8 domain
- Count scenarios per domain
- Identify cross-domain dependencies
- Create domain groupings as per your architecture:
  ```
  features/
  ├── security/         # Which .feature files belong here?
  ├── employee/         # Which .feature files belong here?
  ├── scheduling/       # etc...
  ```

### 2. Current Agent Analysis
For each R-agent directory:
- What they've already discovered/implemented
- Current file organization
- Existing CLAUDE.md instructions
- Identify what can be reused vs restructured

### 3. Migration Plan
Create step-by-step migration plan:
1. How to reorganize BDD specs by domain
2. How to separate Argus findings from our implementation
3. How to create shared/ libraries from existing KNOWLEDGE
4. How to set up workspaces/ for agent collaboration
5. What .codexignore patterns we need

### 4. Tooling Requirements
Based on your architecture recommendations:
- Scripts needed for BDD coverage tracking
- Agent coordination mechanisms
- Git workflow automation
- MCP server configurations

## Expected Output

### 1. Domain Mapping Table
```
| Domain | R-Agent | Feature Files | Scenario Count | Dependencies |
|--------|---------|---------------|----------------|--------------|
| security | R1 | auth.feature, roles.feature... | 98 | shared/auth |
| ...etc |
```

### 2. File Movement Plan
```bash
# Example commands for restructuring
mv project/specs/working/01-authentication-login.feature features/security/
mv project/specs/working/05-complete-step-by-step-requests.feature features/employee/
# ... for all 42 files
```

### 3. Prioritized Migration Steps
1. Create new directory structure
2. Move and organize BDD specs
3. Set up agent workspaces
4. Configure .codexignore hierarchies
5. Update AGENTS.md files

## Key Question to Answer
How can we migrate from our current mixed structure to your recommended architecture while:
- Preserving all R-agent work
- Maintaining Git history
- Enabling parallel agent work immediately
- Achieving 95% BDD coverage target