# Updated Monorepo Migration Plan (AGENTS.md Based)

## Critical Context Management Change
Since .codexignore doesn't exist, we must use hierarchical AGENTS.md files to guide agent behavior through instructions, not enforcement.

## Revised Directory Structure
```
wfm-system/
├── AGENTS.md                    # Root instructions
├── agents/
│   ├── AGENTS.md               # Agent-level scope control
│   ├── R1-SecurityAdmin/
│   │   ├── AGENTS.md          # R1-specific instructions
│   │   ├── src/
│   │   └── tests/
│   └── R2-R8.../
├── features/
│   ├── AGENTS.md              # "Focus on BDD specs only"
│   ├── security/
│   └── employee/
├── shared/
│   └── AGENTS.md              # "Common libraries - read-only"
├── workspaces/
│   ├── AGENTS.md              # "Agent collaboration area"
│   ├── discovery/
│   ├── implementation/
│   └── validation/
└── deployment/
    └── AGENTS.md              # "DO NOT READ - contains secrets"
```

## AGENTS.md Content Strategy

### Root AGENTS.md
```markdown
# WFM Multi-Agent System

## Repository Scope Guidelines

### For Discovery Phase
Please focus on:
- `features/` - BDD specifications
- `workspaces/discovery/` - Write findings here

Please ignore:
- `deployment/` - Contains environment-specific configs
- `*.env`, `*.key`, `*.pem` - Security files
- Large binary files

### For Implementation Phase
Please focus on:
- `agents/R{n}/` - Your assigned domain
- `shared/` - Common libraries (read-only)
- `workspaces/implementation/` - Coordination files

Please ignore:
- Other R-agent directories (unless checking interfaces)
- `deployment/` - Not needed for development
```

### Domain-Specific AGENTS.md (e.g., R1-SecurityAdmin)
```markdown
# R1-SecurityAdmin Agent Instructions

## Your Scope
- **Primary**: `agents/R1-SecurityAdmin/src/`
- **Tests**: `agents/R1-SecurityAdmin/tests/`
- **Specs**: `features/security/*.feature`
- **Shared**: `shared/auth/`, `shared/schemas/security/`

## Please Ignore
- `../R2*/` through `../R8*/` - Other agent domains
- `deployment/` - Deployment configurations
- `workspaces/` - Unless coordinating with orchestrator

## Key Tasks
1. Implement security features from BDD specs
2. Ensure 95% coverage of security scenarios
3. Document APIs in `shared/schemas/security/`
```

## Migration Steps (Updated)

### Phase 1: Create AGENTS.md Hierarchy
```bash
# 1. Root AGENTS.md with repository overview
echo "# WFM Multi-Agent System..." > AGENTS.md

# 2. Create domain AGENTS.md files
for domain in R1-SecurityAdmin R2-Employee R3-Schedule R4-Forecast R5-Manager R6-Integration R7-Reports R8-Mobile; do
  mkdir -p agents/$domain
  echo "# $domain Agent Instructions..." > agents/$domain/AGENTS.md
done

# 3. Workspace AGENTS.md files
mkdir -p workspaces/{discovery,implementation,validation}
echo "# Discovery Workspace..." > workspaces/discovery/AGENTS.md
```

### Phase 2: Organize BDD by Domain
Since we can't enforce ignoring with .codexignore, use clear directory structure:
```bash
# Move BDD specs to domain folders
mkdir -p features/{security,employee,scheduling,forecasting,manager,integration,reporting,mobile}

# Examples (based on Deep Research recommendations):
mv project/specs/working/01-authentication-login.feature features/security/
mv project/specs/working/05-complete-step-by-step-requests.feature features/employee/
# ... etc for all 42 files
```

### Phase 3: Create Agent Isolation Through Instructions
```markdown
# In each R-agent AGENTS.md:

## Collaboration Protocol
When you need to check another domain's interface:
1. Look ONLY at `../R{n}/src/interfaces/public/`
2. Do NOT browse their internal implementation
3. Document dependencies in `workspaces/implementation/dependencies.json`

## Phase-Specific Focus
- During DISCOVERY: Read `features/`, write to `workspaces/discovery/`
- During IMPLEMENTATION: Work in your `src/`, ignore others
- During VALIDATION: Read test results in `workspaces/validation/`
```

## Practical Context Management Without .codexignore

### 1. Directory Naming Conventions
```
_archive/        # Prefix with _ to discourage reading
.old/            # Hidden directories are naturally skipped
deployment-DO-NOT-READ/  # Clear naming
```

### 2. File Organization
```
src/
├── public/      # Interfaces other agents can use
├── internal/    # Implementation details
└── README.md    # "For public API, see public/"
```

### 3. Secrets Management
As noted, use Codex's "Secrets / Env Vars" panel instead of files:
- Never commit .env files
- Use environment variable injection
- Document required vars in AGENTS.md

## Benefits of This Approach

1. **Works Today** - No waiting for .codexignore feature
2. **Human-Readable** - Instructions clear for both AI and developers
3. **Flexible** - Social contract allows judgment calls
4. **Hierarchical** - Natural scoping through folder structure

## Next Steps

1. Create comprehensive AGENTS.md hierarchy
2. Test with one domain (R1-SecurityAdmin)
3. Refine instructions based on agent behavior
4. Roll out to all domains

This approach provides practical context management using only officially supported features!