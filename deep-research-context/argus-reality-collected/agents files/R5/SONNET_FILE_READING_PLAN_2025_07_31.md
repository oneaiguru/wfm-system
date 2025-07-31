# R5 Domain Package Testing - File Reading Plan for Sonnet

**Date**: 2025-07-31
**Agent**: R5-ManagerOversight
**Purpose**: Prepare Sonnet to test domain package approach

## 🎯 Objective

Sonnet needs to test the new domain package approach that promises to transform our discovery rate from 22% to 95%. This requires reading specific files to understand the context, methodology, and technical details.

## 📚 Files Sonnet Must Read (In Priority Order)

### 1. Core Configuration Files
```bash
# Domain package - THE CRITICAL FILE
/Users/m/Documents/wfm/main/project/deep-research-context/r5e.json

# R5 agent configuration
/Users/m/Documents/wfm/main/agents/R5/CLAUDE.md

# Common knowledge for all R-agents
/Users/m/Documents/wfm/main/agents/KNOWLEDGE/R_AGENTS_COMMON.md
```

### 2. Previous Work Context
```bash
# Comprehensive handoff from previous session
/Users/m/Documents/wfm/main/agents/R5/R5_COMPREHENSIVE_SESSION_HANDOFF_2025_07_31.md

# Domain package analysis
/Users/m/Documents/wfm/main/agents/R5/DOMAIN_PACKAGE_ANALYSIS_2025_07_31.md

# Missing APIs discovered
/Users/m/Documents/wfm/main/agents/R5/MISSING_APIS_DISCOVERED.md
```

### 3. BDD Specification Files
```bash
# Working specs directory (to verify scenarios)
/Users/m/Documents/wfm/main/project/specs/working/03-complete-business-process.feature
/Users/m/Documents/wfm/main/project/specs/working/13-business-process-management-workflows.feature
/Users/m/Documents/wfm/main/project/specs/working/16-personnel-management-organizational-structure.feature
/Users/m/Documents/wfm/main/project/specs/working/15-real-time-monitoring-operational-control.feature
```

### 4. Technical Resources
```bash
# API registry to compare with package
/Users/m/Documents/wfm/main/agents/KNOWLEDGE/API/_ALL_ENDPOINTS.md

# Component registry to verify existence
/Users/m/Documents/wfm/main/agents/KNOWLEDGE/COMPONENTS/_ALL_COMPONENTS.md

# MCP login procedures
/Users/m/Documents/wfm/main/agents/COMMON_MCP_LOGIN_PROCEDURES.md
```

### 5. Progress Tracking
```bash
# Current progress status
/Users/m/Documents/wfm/main/agents/R5/progress/status.json

# Session reports directory
/Users/m/Documents/wfm/main/agents/R5/session_reports/
```

### 6. Architecture Understanding
```bash
# Dual portal architecture
/Users/m/Documents/wfm/main/agents/KNOWLEDGE/ARCHITECTURE/DUAL_PORTAL_COMPLETE_ANALYSIS.md

# Navigation map with R5 discoveries
/Users/m/Documents/wfm/main/agents/HTML-RESERACH/NAVIGATION_MAP.md
```

## 📊 File Size Estimates

- **Critical Files**: ~15K tokens (domain package + handoff)
- **BDD Specs**: ~20K tokens (4 feature files)
- **Knowledge Base**: ~10K tokens (APIs, components, procedures)
- **Architecture**: ~5K tokens
- **Total**: ~50K tokens

## 🎯 Key Information Sonnet Needs to Extract

### From Domain Package (r5e.json):
1. All 69 scenario IDs and names
2. Navigation URLs for both portals
3. Component status (verified/unverified/missing)
4. API registry with status
5. Cross-domain dependencies

### From Previous Work:
1. 15 scenarios we already found
2. 54 scenarios we missed
3. Hidden features discovered
4. Missing APIs identified

### From BDD Specs:
1. Exact scenario text for each SPEC-XXX
2. Given/When/Then steps
3. Technical requirements

### From Knowledge Base:
1. Existing API endpoints to compare
2. Existing components to verify
3. MCP login sequences

## ✅ Success Criteria for Sonnet

After reading these files, Sonnet should be able to:
1. List all 69 scenarios with their locations
2. Navigate directly to key pages using URLs
3. Test verified APIs first to build confidence
4. Test unverified endpoints systematically
5. Search for missing components
6. Provide evidence chains for each test

## 🚫 What Sonnet Should NOT Do

1. Don't make assumptions about features
2. Don't claim completion without MCP evidence
3. Don't skip the verified APIs (build confidence first)
4. Don't test all 69 scenarios (unrealistic in one session)
5. Don't modify the domain package file

---

**Next Step**: Have Sonnet read these files, then I'll provide the detailed execution plan.