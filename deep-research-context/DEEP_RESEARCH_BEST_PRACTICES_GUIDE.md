# Deep Research Best Practices Guide

## 🎯 What is Deep Research?

Deep Research is an AI service that analyzes large codebases and documents to provide comprehensive insights. It excels at:
- Cross-referencing multiple files
- Finding patterns across repositories
- Creating structured analyses
- Generating implementation guides

## 📋 General Best Practices

### 1. **Start with Clear Context**
```markdown
## Context
[2-3 sentences explaining the problem/goal]

## Current Situation
[What exists now and why change is needed]
```

### 2. **Be Explicit About Scope**
```markdown
## What to Analyze
- Specific folder paths
- File patterns (*.feature, *.md)
- Key relationships to discover

## What to Ignore
- Folders containing irrelevant code
- File types to skip
- Known pollution sources
```

### 3. **Provide Clear Output Structure**
```markdown
## Expected Output
1. **Section Name**
   - Specific format/structure
   - Example of desired output
   
2. **Another Section**
   - Clear requirements
   - Measurable success criteria
```

### 4. **Use Concrete Examples**
Instead of: "Analyze the architecture"
Better: "Find all REST endpoints and map them to their controllers"

### 5. **Set Boundaries**
```markdown
## Constraints
- Output size limits (e.g., <100KB per file)
- Focus areas (e.g., only production code)
- Time/complexity boundaries
```

## 🚀 Optimal Request Structure

```markdown
# Deep Research Request: [Clear Title]

## Objective
[One sentence goal]

## Context
[2-3 paragraphs of background]

## Repository Structure
```
/project/
├── folder1/        # Description
├── folder2/        # Description
└── folder3/        # Description
```

## Specific Tasks
1. **Task 1**: [Concrete deliverable]
   - Input: [What to analyze]
   - Output: [Expected format]
   - Example: [Sample output]

2. **Task 2**: [Another deliverable]
   - Input: [Sources]
   - Output: [Format]
   - Success Criteria: [Measurable]

## What to Analyze
- ✅ Path 1
- ✅ Path 2
- ✅ Pattern (*.extension)

## What to Ignore
- ❌ Path A
- ❌ Path B
- ❌ Pattern (*.exclude)

## Output Requirements
- Format: JSON/Markdown/Code
- Structure: [Specific template]
- Size: [Constraints]

## Success Metrics
- [ ] Deliverable 1 complete
- [ ] Deliverable 2 complete
- [ ] Quality criteria met
```

## ⚠️ Common Pitfalls to Avoid

### 1. **Vague Instructions**
❌ "Analyze the codebase and create documentation"
✅ "Create a component inventory with usage counts and dependencies"

### 2. **No Folder Guidance**
❌ "Look at the project"
✅ "Analyze `/src/` for components, ignore `/tests/` and `/build/`"

### 3. **Unclear Output Format**
❌ "Provide insights"
✅ "Create a JSON file with this structure: {component: string, usage: number[]}"

### 4. **Missing Context**
❌ Starting with tasks immediately
✅ Explaining why this analysis is needed and what problem it solves

### 5. **No Success Criteria**
❌ "Find issues"
✅ "Identify all components without tests (coverage < 80%)"

## 📊 Quick Checklist

Before submitting a Deep Research request:

- [ ] Clear one-sentence objective?
- [ ] Context explains the "why"?
- [ ] Specific folders/files to analyze?
- [ ] Explicit ignore list?
- [ ] Concrete output examples?
- [ ] Measurable success criteria?
- [ ] Size/scope constraints defined?

## 💡 Time-Saving Tips

1. **Create a Template**: Save a base request structure for your project
2. **Use Previous Results**: Reference successful past analyses
3. **Test Small First**: Try with one folder before full repository
4. **Version Your Requests**: Keep improving based on results

---

## 📌 Real Example: WFM System Domain Package Request

### What Went Wrong Initially:
- Deep Research analyzed our implementation code instead of real system
- No clear boundaries between "reference" vs "implementation"
- Vague scope led to polluted results

### The Fixed Request:

```markdown
# Deep Research Request: Create Domain Packages from REAL Argus System

## 🚨 CRITICAL CONTEXT: Previous Pollution Issue
Our previous domain packages were contaminated because they analyzed our implementation code instead of real Argus findings. This request fixes that by providing ONLY verified Argus system data.

## ⚠️ CRITICAL INSTRUCTIONS

### ONLY Analyze These Folders:
- ✅ `argus-reality-only/` - Contains ONLY verified findings from real Argus system
- ✅ `bdd-specs/` - Feature specifications (when available)

### COMPLETELY IGNORE These:
- ❌ `our-implementation/` - Our WFM replica code (NOT Argus)
- ❌ `verified-knowledge/` - Old polluted data
- ❌ Any files containing `/api/v1/*` REST endpoints

## 📁 Repository Structure You'll Find
[Clear folder tree showing what's what]

## 🎯 Your Task
Create domain packages for R1-R8 agents based ONLY on verified Argus findings.

## 📋 Expected Domain Package Structure
[Concrete JSON example with all required fields]
```

### Why This Worked:
1. **Clear Context**: Explained the pollution problem upfront
2. **Explicit Boundaries**: ✅ and ❌ lists for folders
3. **Concrete Examples**: Showed exact JSON structure wanted
4. **Focused Scope**: Only analyze specific folders
5. **Clear Output**: Domain packages with specific format

### Time Saved:
- First attempt: 3+ hours of back-and-forth
- Fixed request: Single run with correct results

## 🎯 Key Takeaway

**Invest 10 minutes in a clear request to save hours of iteration!**

The clearer your boundaries and examples, the better Deep Research performs. When in doubt, be MORE specific, not less.