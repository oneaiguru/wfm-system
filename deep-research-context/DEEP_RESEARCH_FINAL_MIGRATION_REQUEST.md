# Deep Research: Final Migration Analysis Request

## Context
- We have your excellent monorepo architecture recommendations
- .codexignore doesn't exist - we must use AGENTS.md files instead
- We already have R1-R8 agent structure in place
- Need to map 586 BDD scenarios to domains and create migration plan

## Critical Directories to Analyze

### 1. BDD Specifications (PRIORITY)
**Location**: `/project/specs/working/*.feature`
**Task**: Map all 42 feature files to R1-R8 domains
**Output**: Table showing which features belong to which domain

### 2. Existing R-Agent Structure  
**Location**: `/agents/R*`
**Task**: Inventory what each agent has already done
**Focus on**:
- R1-AdminSecurity
- R2-Employee
- R3-Schedule
- R4-Forecast
- R5-Manager
- R6-Integration
- R7-Reports
- R8-Mobile

### 3. Real Argus Documentation
**Location**: `/intelligence/argus/docs-consolidated/База знаний WFM CC/`
**Task**: Map documentation to appropriate domains

### 4. Knowledge Patterns
**Location**: `/agents/KNOWLEDGE/API_PATTERNS/`
**Task**: Identify real JSF patterns to preserve in migration

## Specific Outputs Needed

### 1. BDD-to-Domain Mapping
Create a table like:
```
| Feature File | Scenarios | Best R-Agent | Domain Folder |
|-------------|-----------|--------------|---------------|
| 01-authentication-login.feature | 14 | R1-AdminSecurity | features/security/ |
| 05-complete-step-by-step-requests.feature | 20 | R2-Employee | features/employee/ |
| ... (all 42 files) |
```

### 2. AGENTS.md Templates
Create domain-specific AGENTS.md content for each R-agent that:
- Tells them which feature files to focus on
- Instructs them to ignore other domains
- Defines their workspace boundaries

### 3. Migration Script
```bash
#!/bin/bash
# Concrete commands to reorganize repository

# Create new structure
mkdir -p features/{security,employee,scheduling,forecasting,manager,integration,reporting,mobile}
mkdir -p workspaces/{discovery,implementation,validation}
mkdir -p shared/{core,protocols,schemas}

# Move BDD files (specific examples for all 42 files)
mv project/specs/working/01-authentication-login.feature features/security/
# ... etc
```

### 4. Coverage Analysis
For each domain, calculate:
- Total scenarios assigned
- Current implementation status
- Gap to 95% target

## Key Constraints

1. **No .codexignore** - Must use AGENTS.md instructions only
2. **Preserve Git history** - Use `mv` not `cp`
3. **Keep agents working** - No breaking changes
4. **Argus reality** - Separate from our implementation

## Questions to Answer

1. Which of the 42 feature files belong to which R-agent domain?
2. How many scenarios does each domain need to implement?
3. What's the optimal order for migration steps?
4. Which shared components need to be extracted?
5. How to organize Argus findings vs our implementation?

Please analyze the actual repository structure and provide concrete migration steps!