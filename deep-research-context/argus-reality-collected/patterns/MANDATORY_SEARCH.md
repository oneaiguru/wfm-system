# 🔍 MANDATORY SUBAGENT SEARCH PATTERN

## ⚡ CRITICAL: This Pattern is REQUIRED for ALL Work

### The Problem We're Solving:
- **70% duplication** when agents don't search first
- **Wasted effort** recreating existing components
- **Inconsistency** when patterns aren't reused
- **Hidden gems** remain undiscovered

## 📋 The Mandatory Pattern:

### BEFORE ANY IMPLEMENTATION:
```python
# MANDATORY FIRST STEP - NO EXCEPTIONS
existing_assets = Task(
    description="Find existing [feature] implementations",
    prompt="""Read at least 30 files searching for:
    - Existing [feature] code/patterns/implementations
    - Similar functionality or components
    - Test examples and patterns
    - Related database/API/UI elements
    
    Search locations: [relevant directories]
    Return: Full paths to reusable code with summaries."""
)

print(existing_assets)
```

### Only AFTER Search Results:
1. **Review findings** - What already exists?
2. **Identify reusable** - What can be adapted?
3. **Document gaps** - What's truly new?
4. **Build on existing** - Extend, don't recreate

## 🎯 Agent-Specific Examples:

### BDD-SCENARIO-AGENT:
```python
bdd_search = Task(
    description="Find existing BDD scenarios",
    prompt="""Search 30+ files for:
    - Similar test scenarios
    - BDD patterns for this feature
    - Test data structures
    - Workflow examples"""
)
```

### DATABASE-OPUS:
```python
db_search = Task(
    description="Find existing database schemas",
    prompt="""Search 30+ files for:
    - Related tables
    - Similar schemas
    - Database functions
    - Performance patterns"""
)
```

### INTEGRATION-OPUS:
```python
api_search = Task(
    description="Find existing API endpoints",
    prompt="""Search 30+ files for:
    - Similar endpoints
    - API patterns
    - Response formats
    - Auth patterns"""
)
```

### UI-OPUS:
```python
ui_search = Task(
    description="Find existing UI components",
    prompt="""Search 30+ files for:
    - Similar components
    - UI patterns
    - Form structures
    - Display layouts"""
)
```

### ALGORITHM-OPUS:
```python
algo_search = Task(
    description="Find existing algorithms",
    prompt="""Search 30+ files for:
    - Similar calculations
    - Algorithm patterns
    - Performance code
    - Business logic"""
)
```

## ✅ Success Metrics:

### When Done Right:
- **70% code reuse** instead of recreation
- **Consistent patterns** across system
- **Faster delivery** through adaptation
- **Higher quality** from proven code

### Red Flags:
- Starting to code immediately
- "I'll just build it from scratch"
- Not finding ANY existing patterns
- Skipping the search step

## 📊 Tracking Compliance:

Each task completion MUST show:
```markdown
## Subagent Search Results:
- Files searched: 30+
- Existing patterns found: [list]
- Reused components: [list with %]
- New components created: [only what's necessary]
- Reuse percentage: X% (target: >70%)
```

## 🚨 Enforcement:

**Work will be REJECTED if:**
- No evidence of subagent search
- Recreation of existing components
- Pattern inconsistency
- Zero reuse when similar code exists

## 💡 Remember:

> "The best code is the code you don't write"

Search first. Reuse always. Create only when necessary.

---

**This pattern is MANDATORY for all agents, all tasks, no exceptions.**