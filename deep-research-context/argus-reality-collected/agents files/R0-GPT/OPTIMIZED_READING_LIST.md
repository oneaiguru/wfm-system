# 📚 Optimized Reading List for BDD Verification

## 🔴 ESSENTIAL FILES (Always Read)

### 1. MCP_TOOL_USAGE_GUIDE.md (NEW!)
- **Why**: Critical for avoiding 403 errors
- **What**: Which MCP server to use for Argus vs localhost
- **When**: Before ANY web exploration

### 2. VERIFICATION_STATUS.md 
- **Why**: Know what's done and what's next
- **What**: Current progress (5/32 specs done)
- **When**: Start of each session

### 3. INTEGRATION_PATTERNS_LIBRARY_UPDATED.md
- **Why**: 6 proven patterns to apply
- **What**: Route fixes, form accessibility, test IDs
- **When**: When fixing integration gaps

### 4. APPROACH.md
- **Why**: Step-by-step methodology
- **What**: How to verify specs systematically
- **When**: For each new spec

## 🟡 USEFUL BUT SELECTIVE (Read Specific Parts)

### 5. BDD_UI_MAPPING.md
- **Read**: Only Demo Value 5 sections
- **Skip**: Detailed component lists
- **Use Task**: Search for specific component status

### 6. Journey Analysis Files (VACATION_JOURNEY_COMPLETE.md, etc)
- **Read**: Integration gaps summary sections
- **Skip**: Line-by-line code analysis
- **Use Task**: Find specific pattern applications

### 7. BDD Spec Files (/project/specs/working/*.feature)
- **Read**: Only the scenario being verified
- **Skip**: Entire 300+ line files
- **Use**: Grep for specific scenarios

## 🟢 REFERENCE ONLY (Don't Read Unless Needed)

### 8. Argus Documentation
- **Why Skip**: Can't access Argus anyway (403)
- **When Needed**: Only if comparing specific features
- **Alternative**: Use existing analyses

### 9. Component Implementation Files
- **Why Skip**: Too detailed for verification
- **When Needed**: Only to check if feature exists
- **Use Task**: Search for specific functionality

### 10. Test Files
- **Why Skip**: Tests show expectations, not reality
- **When Needed**: To understand integration patterns
- **Use**: Grep for specific test scenarios

## 🔵 TASK TOOL STRATEGY

### Use Task Tool First For:
1. **Finding existing work**: "Search for SPEC-XX analysis"
2. **Component discovery**: "Find all profile-related components"
3. **Pattern matching**: "Find examples of Pattern 4 application"
4. **Status checking**: "What specs are still pending?"

### Then Read Only What's Essential:
- Specific line ranges identified by Task
- Gap summaries, not full analyses
- Pattern applications, not theory

## 📊 Reading Efficiency Metrics

**Previous Approach**: Read 500+ lines per spec
**Optimized Approach**: Read 50-100 lines per spec
**Efficiency Gain**: 80% reduction in reading

## 🎯 For Next Session - EXACT READING LIST

### Phase 1: Essential Context (Read First)
1. `/agents/GPT-AGENT/MCP_TOOL_USAGE_GUIDE.md` (CRITICAL - avoid 403)
2. `/agents/GPT-AGENT/VERIFICATION_STATUS.md` (know what's done)
3. `/agents/GPT-AGENT/OPTIMIZED_READING_LIST.md` (this file - methodology)

### Phase 2: Current Work Status
4. `/agents/AGENT_MESSAGES/FROM_B2_TO_GPT_BATCH_2_ASSIGNMENT.md` (SPECs 19-25)
5. `/agents/GPT-AGENT/analysis/spec-23-*.md` (if exists - check last work)

### Phase 3: Registry Evaluation (New Priority!)
6. `/agents/AGENT_MESSAGES/FROM_B2_TO_GPT_REGISTRY_EVALUATION_REQUEST.md`
7. `/project/specs/registry/MASTER_INDEX.md` (test the registry)
8. `/agents/AGENT_MESSAGES/FROM_O_TO_R_BDD_REGISTRY_READY.md` (O's instructions)

### Phase 4: Apply Patterns (Only If Needed)
9. `/agents/BDD-SCENARIO-AGENT-2/INTEGRATION_PATTERNS_LIBRARY_UPDATED.md` (Pattern 1-6)
10. Specific journey file ONLY if similar issue found

### Total Reading: ~200 lines (manageable!)

## 📋 Next Session TODO List

1. **Complete SPEC-23** (Request History)
2. **Complete SPEC-24 & 25** if time permits
3. **Test Registry System** - give feedback to B2
4. **Create B2 Response Message** - summarize Batch 2 findings
5. **Update VERIFICATION_STATUS.md** - mark Batch 2 complete

## 🚨 DO NOT READ (Unless Absolutely Necessary)
- Argus documentation (can't access anyway)
- Full BDD feature files (use registry instead)
- Component implementation files (too detailed)
- Test files (shows expectations not reality)
- Journey files in full (only specific patterns)

## 🎯 Success Metrics for Next Session
- Complete remaining 3 specs in Batch 2
- Evaluate registry in <15 minutes
- Create comprehensive B2 response
- Maintain <500 lines total reading

This approach gets us to the same understanding with 80% less reading!