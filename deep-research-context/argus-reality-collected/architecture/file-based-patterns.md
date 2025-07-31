# File-Based Coordination Patterns

*Extracted from ORCHESTRATOR-ARCHITECT analysis by MD-CURATOR on 2025-07-18*

## 🎯 Why Files Win Over Complex Systems

Deep research into 340+ sources revealed that **file-based coordination consistently outperforms complex distributed systems** in Claude Code environments.

## 📊 Core File-Based Patterns

### 1. **available-tasks/ State Machine**
**Pattern**: Directory structure as state management
**Evidence**: Successful across DATABASE-OPUS, ALGORITHM-OPUS, UI-OPUS
**Performance**: 90%+ success rate vs complex protocols

```bash
# State transitions through file movement
available-tasks/implement-auth.md     # Ready to work
in-progress/implement-auth.md         # Agent working
completed-tasks/implement-auth.md     # Done
```

### 2. **Knowledge Through @imports**
**Pattern**: Pre-load context via file references
**Evidence**: Eliminates runtime query complexity
**Constraint**: Works within context window limits

```markdown
# Agent CLAUDE.md
@../KNOWLEDGE/SCHEMA/_ALL_TABLES.md
@../KNOWLEDGE/API/_ALL_ENDPOINTS.md

# Simple, reliable, no runtime dependencies
```

### 3. **Git as Message Bus**
**Pattern**: Commits as coordination signals
**Evidence**: Natural versioning, conflict resolution, history
**Success**: No custom messaging infrastructure needed

```bash
# Agent coordination through commits
git commit -m "TASK_COMPLETE: Implemented auth endpoint"
git commit -m "SCHEMA_DEPLOYED: 18 tables ready for integration"
```

### 4. **Single Source of Truth Files**
**Pattern**: Centralized configuration in simple files
**Evidence**: Eliminated port confusion across multiple agents
**Example**: `/agents/SERVER_PORT_REGISTRY.md`

## 🔧 Implementation Techniques

### State Management Through Directories
```
AGENT-NAME/
├── available-tasks/     # Work queue
│   ├── task-1.md
│   └── task-2.md
├── in-progress/         # Current work
│   └── active-task.md
├── completed-tasks/     # Done
│   └── finished-task.md
└── blocked-tasks/       # Issues
    └── blocked-task.md
```

### Knowledge Distribution
```
KNOWLEDGE/
├── AGENTS/              # Agent coordination patterns
├── ARCHITECTURE/        # System design decisions  
├── ALGORITHMS/          # Algorithm registry
├── API/                 # Endpoint documentation
├── SCHEMA/              # Database knowledge
└── PATTERNS/            # Reusable solutions
```

### Communication Patterns
```
AGENT_COMMUNICATION/
├── NEEDS/               # What agents need
│   ├── AL_NEEDS.md
│   ├── INT_NEEDS.md
│   └── UI_NEEDS.md
└── READY/               # What's available
    ├── DB_READY.md
    └── API_READY.md
```

## 📊 Performance Evidence

### Coordination Success
- **DATABASE-OPUS**: Coordinated with 3 agents via NEEDS/READY files
- **Schema deployment**: Unblocked multiple agents simultaneously
- **Port registry**: Eliminated confusion across all agents
- **File-based locks**: Prevented multi-agent conflicts

### Speed Improvements  
- **Instant state visibility**: Directory listing shows current work
- **No network dependencies**: All local file operations
- **Git history**: Complete audit trail automatically
- **Context loading**: Pre-loaded via @imports

### Reliability Benefits
- **No network failures**: File system is always available
- **Atomic operations**: Move operations are atomic
- **Version control**: Git handles conflicts naturally
- **Simple debugging**: File contents are human-readable

## 🚨 Anti-Patterns (What Fails)

### Complex Systems That Don't Work
- **Runtime database queries** for coordination
- **HTTP API calls** between agents
- **Complex messaging protocols**
- **Distributed consensus algorithms**
- **Dynamic configuration** updates

### Why They Fail in Claude Code
- **Context window limits**: Can't maintain connection state
- **No hot reload**: Changes not detected during session
- **Session boundaries**: State lost between sessions
- **Token consumption**: Complex protocols eat context
- **Debugging difficulty**: Hard to trace failures

## 🎯 Implementation Guidelines

### Design Principles
1. **Files First**: Default to file-based solutions
2. **Simple Movement**: Use `mv` for state transitions
3. **Human Readable**: All coordination visible in text
4. **Git Native**: Leverage version control features
5. **Context Friendly**: Minimize token usage

### Setup Requirements
```bash
# Create agent structure
mkdir -p AGENT-NAME/{available-tasks,in-progress,completed-tasks}

# Initialize git tracking
git add AGENT-NAME/
git commit -m "Initialize AGENT-NAME coordination"

# Create communication channels
mkdir -p AGENT_COMMUNICATION/{NEEDS,READY}
```

### Coordination Protocol
```bash
# Orchestrator creates work
echo "Task description" > AGENT/available-tasks/task-name.md

# Agent picks up work  
mv AGENT/available-tasks/task-name.md AGENT/in-progress/

# Agent completes work
mv AGENT/in-progress/task-name.md AGENT/completed-tasks/

# Signal completion
git add . && git commit -m "TASK_COMPLETE: task-name"
```

## 🔄 File Lock Patterns

### Preventing Conflicts
```bash
# Before processing
echo "$$" > .locks/filename.lock

# Do work safely
process_file.py filename

# Release lock
rm .locks/filename.lock
```

### Heartbeat Monitoring
```bash
# Agent heartbeat every 2 minutes
echo "$(date)" > .heartbeats/agent-name.heartbeat

# Monitor for stuck agents (timeout after 5 minutes)
find .heartbeats -name "*.heartbeat" -mmin +5
```

## 📈 Scaling Characteristics

### Advantages
- **Linear scaling**: More agents = more directories
- **No central bottleneck**: Each agent manages own state
- **Simple monitoring**: File system tools show status
- **Easy recovery**: Failed state visible in directories

### Limitations
- **File system performance**: Large numbers of files
- **Git repository size**: Grows with coordination history
- **Directory scanning**: Linear search for some operations
- **Platform differences**: File system behavior varies

### Solutions
- **Periodic cleanup**: Archive old completed tasks
- **Shallow git clones**: Limit history for working agents
- **Indexed access**: JSON files for quick lookups
- **Platform abstraction**: Standard path handling

## 🎯 Success Patterns

### Proven Implementations
1. **Task Distribution**: available-tasks/ → in-progress/ → completed-tasks/
2. **Knowledge Sharing**: @imports in CLAUDE.md files
3. **Status Tracking**: File presence indicates state
4. **Communication**: Structured files in shared directories
5. **Configuration**: Single truth files prevent confusion

### Quality Indicators
- **Immediate visibility**: `ls` shows current state
- **Version history**: `git log` shows progression
- **Conflict resolution**: Git merge handles simultaneously
- **Human debugging**: Text files readable without tools
- **Recovery simplicity**: Copy/move files to fix issues

---

**Source**: DEEP_ANALYSIS_FILE_BASED_COORDINATION.md, practical implementation evidence
**Date Extracted**: 2025-07-18
**Confidence**: Extremely High (proven across multiple agents, consistent research findings)
**Status**: Production-ready pattern, recommended for all coordination