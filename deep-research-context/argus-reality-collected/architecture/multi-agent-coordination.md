# Multi-Agent Coordination Architecture

**Source**: MD-CURATOR extraction from session handoffs  
**Date**: 2025-07-18  
**Value**: High - Production-proven patterns

## Core Patterns

### 1. Parallel Verification Pattern
- **Problem**: Sequential debugging leads to whack-a-mole issues
- **Solution**: Deploy paired verification agents (D+I, I+U, U+A, A+D)
- **Result**: 138 issues found in 2 hours vs weeks of sequential discovery

### 2. Port Registry Pattern
- **Problem**: Agent confusion about service ports
- **Solution**: Single source of truth in SERVER_PORT_REGISTRY.md
- **Implementation**: All agents reference central registry

### 3. Modular CLAUDE.md Pattern
- **Problem**: Large context files become unmaintainable
- **Solution**: 41-line master file with @imports
- **Benefits**: Maintainable, scalable, clear separation of concerns

### 4. Integration-First Development
- **Principle**: Align agents before building features
- **Order**: Port registry → Schema alignment → Basic integration → Features
- **Metrics**: 4x-10x faster than sequential approach

## Implementation Templates

### Port Registry Template
```markdown
| Service | Port | Status | Process |
|---------|------|--------|---------|
| API     | 8001 | ✅ ACTIVE | python3.9 |
| UI      | 3001 | ✅ ACTIVE | node |
```

### Verification Script Template
```bash
# System verification
psql -c "SELECT COUNT(*) FROM information_schema.tables"
find /project/src -name "*.tsx" | wc -l
curl http://localhost:8001/docs | grep -c "real"
```

## Success Metrics
- **Systematic vs Sequential**: 4x-10x faster
- **Integration Success**: 6.6% → First working BDD scenario
- **Context Management**: 200+ lines → 41 lines
- **Issue Discovery**: 138 issues in 2 hours

## Usage Guidelines
- Apply parallel verification for complex integration issues
- Use port registry for multi-service systems
- Modularize CLAUDE.md files over 100 lines
- Prioritize integration alignment over feature development

---
**Status**: Production-proven  
**Next Evolution**: Universal System Replicator integration