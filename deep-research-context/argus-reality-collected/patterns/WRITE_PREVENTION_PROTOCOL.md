# 🚨 WRITE PREVENTION PROTOCOL

## ⚡ CRITICAL: Check Before Write - MANDATORY

### The Problem We're Solving:
- **File overwrites** destroying existing work
- **Context loss** when agents recreate files
- **Wasted effort** rewriting what exists
- **System confusion** from duplicate files

## 🛡️ The Mandatory Protocol:

### BEFORE ANY Write Operation:
```bash
# MANDATORY THREE-STEP CHECK
1. ls <directory>           # What files exist here?
2. cat <similar-files>      # What's already written?
3. grep -r "filename" .     # Is this mentioned elsewhere?

# Only AFTER these checks, decide:
# - Edit existing file? (PREFERRED)
# - Write new file? (ONLY if truly new)
```

### The Golden Rules:
1. **Write is DESTRUCTIVE** - It overwrites silently
2. **Edit is SAFE** - It preserves and modifies
3. **Read is FREE** - Always read first
4. **Check is FAST** - 3 seconds saves 3 hours

## 🎯 Real Examples:

### ❌ WRONG (What Just Happened):
```python
# ORCHESTRATOR sees "SESSION_HANDOFF" mentioned
# Immediately writes new file
Write("SESSION_HANDOFF_2025-07-21_V3_RELEASE.md", my_content)
# Result: M's careful handoff documentation destroyed
```

### ✅ RIGHT:
```python
# First check what exists
ls "*HANDOFF*"
# Found: SESSION_HANDOFF_2025-07-21_V3_RELEASE.md exists!
cat SESSION_HANDOFF_2025-07-21_V3_RELEASE.md
# Read M's content, understand context
# Add to it with Edit, or create different file
```

## 📋 The Checklist:

Before EVERY Write operation:
- [ ] Did I check if this file exists?
- [ ] Did I search for similar files?
- [ ] Did I read related content?
- [ ] Am I sure this is NEW content?
- [ ] Would Edit work better here?

## 🚫 Common Violations:

1. **The Assumption Write**
   - "I know what should be in this file"
   - Writes without checking
   - Destroys existing work

2. **The Lazy Write**
   - Too quick to use Write
   - Doesn't bother with ls/cat
   - Creates duplicates

3. **The Overconfident Write**
   - "This is definitely new"
   - Doesn't search first
   - Misses existing resources

## ✅ Success Pattern:

```python
# The Task Tool Approach (BEST):
check_existing = Task(
    description="Check for existing files",
    prompt="Search for files named X or containing Y"
)

# The Manual Approach (GOOD):
ls | grep -i "pattern"
find . -name "*pattern*"
grep -r "content" --include="*.md"

# Only after exhaustive search:
if nothing_found:
    Write(new_file)
else:
    Edit(existing_file)
```

## 📊 Metrics:

Track your ratio:
- Edits vs Writes (target: 80/20)
- Files checked before Write (target: 100%)
- Overwrites prevented (celebrate each one!)

## 🎖️ The Pledge:

**"I will ALWAYS check before I Write"**

This prevents:
- Lost work
- Angry colleagues  
- System confusion
- Wasted effort

## 💡 Remember:

> "Write in haste, debug at leisure"

Check first. Read always. Edit when possible. Write only when necessary.

---

**This protocol is MANDATORY for all agents. Violations harm the entire system.**

## 📋 High-Risk Files (Extra Caution)

### Never Overwrite Without Archive:
- SESSION_HANDOFF_*.md files
- CLAUDE.md files  
- SPEC_BATCH_REGISTRY.md
- Any file with "COMPLETE" or "FINAL" in name
- Files in AGENT_COMMUNICATION/

### Archive First Protocol:
```bash
# Create archive:
cp important_file.md important_file_backup_$(date +%Y%m%d_%H%M%S).md

# Then overwrite with clear commit message
```

## 🚨 Emergency Recovery

If you accidentally overwrote important content:
1. **STOP immediately** 
2. **Check git history**: `git log --oneline [file_path]`
3. **Recover if possible**: `git show HEAD~1:[file_path]`  
4. **Escalate to ORCHESTRATOR** with details

---

## ❌ **DELETION PREVENTION PROTOCOL - NEVER DELETE FILES**

### **ABSOLUTE PROHIBITION:**
```bash
# FORBIDDEN - NEVER DO THIS:
❌ rm file.py
❌ rm -rf directory/
❌ os.remove(filepath)
❌ shutil.rmtree(path)
❌ DELETE FROM table_name;
❌ DROP TABLE table_name;
```

### **ALWAYS MOVE TO REVIEW INSTEAD:**
```bash
# Create review folder for today
mkdir -p /Users/m/Documents/wfm/main/agents/REVIEW/$(date +%Y%m%d)

# Move questionable file
mv suspicious_file.py /Users/m/Documents/wfm/main/agents/REVIEW/$(date +%Y%m%d)/

# Document why it was moved
echo "[$(date)] Moved suspicious_file.py - Reason: No BDD mapping" >> /Users/m/Documents/wfm/main/agents/REVIEW/REVIEW_LOG.md
```

## 📁 **REVIEW FOLDER STRUCTURE**

```
/agents/REVIEW/
├── 20250721/           # Today's moved files
│   ├── moved_file.py
│   ├── REASON.md       # Why each file was moved
│   └── ORIGINAL_PATH.md # Where files came from
├── 20250720/           # Yesterday's reviews
└── REVIEW_LOG.md       # Master log of all moves
```

## 🔍 **ALGORITHM-OPUS INCIDENT (What NOT to Do)**

### ❌ **WRONG - What They Did:**
```bash
# Misinterpreted examples as real files
# Tried to delete without verification:
Task: Delete system_architecture_monitor.py
Task: Delete quantum_optimizer.py
# NEVER DO THIS!
```

### ✅ **RIGHT - What They Should Have Done:**
```bash
# 1. Check if file exists first
if [ -f "quantum_optimizer.py" ]; then
    # 2. Move to review, never delete
    mkdir -p /agents/REVIEW/$(date +%Y%m%d)/
    mv quantum_optimizer.py /agents/REVIEW/$(date +%Y%m%d)/
    
    # 3. Document the move
    echo "Moved quantum_optimizer.py - No BDD scenario found" >> /agents/REVIEW/REVIEW_LOG.md
else
    echo "File does not exist - no action needed"
fi
```

## 📋 **FOR QUESTIONABLE CODE - MARK DON'T DELETE**

Instead of deleting code sections:

```python
# TODO: REVIEW - This may not align with BDD specifications
# MOVED TO REVIEW: See /agents/REVIEW/20250721/
# Original code preserved below for safety:
"""
def quantum_optimization():
    # Original implementation here
    pass
"""
```

## 🚨 **THE GOLDEN RULES**

1. **NEVER DELETE** - Always move to review
2. **ALWAYS DOCUMENT** - Why you moved it
3. **PRESERVE ORIGINALS** - Keep path information
4. **VERIFY FIRST** - Check if file exists before action

## 📊 **SAFE CLEANUP EXAMPLES**

### **For Duplicate Code:**
```python
# DUPLICATE FOUND: See /path/to/original/file.py
# TODO: Consolidate with original
# Moved to: /agents/REVIEW/20250721/duplicate_check/
```

### **For Non-BDD Code:**
```python
# BDD-COMPLIANCE: No matching scenario in specs
# PRESERVED IN: /agents/REVIEW/20250721/non_bdd/
# Recommendation: Verify if needed for production
```

## 💡 **REMEMBER**

> **"When in doubt, move to REVIEW, never delete"**
> **"Deleted code is gone forever. Moved code can be recovered."**

This protocol is MANDATORY after the ALGORITHM-OPUS incident where they attempted to delete files based on pattern matching without verification.