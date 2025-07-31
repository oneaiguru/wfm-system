# Deep Research: Monorepo Architecture for Multi-Agent Development

## Context
We're building a WFM system using multiple AI agents (Codex, Claude Code, ChatGPT) working in a monorepo. We need best practices for structuring the repository to maximize agent effectiveness while preventing context pollution and enabling smooth collaboration.

## Research Objectives

### 1. Monorepo Structure for AI Agents
- Optimal directory layouts for multi-agent workflows
- How to organize code so agents find what they need quickly
- Best practices for separating concerns (discovery, implementation, validation)
- Examples from successful AI-assisted projects

### 2. Context Management Strategies
- Advanced .codexignore patterns for different agent contexts
- How to use AGENTS.md files effectively in monorepo subdirectories
- Strategies for preventing agents from reading irrelevant code
- Dynamic context switching techniques

### 3. Agent-Specific Optimization

#### For Codex:
- How to structure repos for Codex's grep-based search
- Optimal file naming for Codex discoverability
- Best practices for AGENTS.md in different directories
- How to handle Codex's Docker environment limitations

#### For Claude Code:
- Local workspace organization for MCP server
- How to structure files for Claude's file reading patterns
- Best practices for project knowledge integration
- Coordination with other agents' outputs

#### For ChatGPT (UAT Agent):
- Organizing test specifications and results
- Structure for screenshot evidence and reports
- Integration with deployment pipelines

### 4. Workflow Patterns
- How to organize a discovery → implementation → validation loop
- File naming conventions that help agents collaborate
- Directory structures that support parallel agent work
- Version control strategies for agent-generated code

### 5. Real-World Examples
Please analyze these specific use cases:



wfm-system/ ├── specs/                    # Single source of truth ├── discovery/               # Multiple agents read/write ├── implementation/          # Multiple agents collaborate └── validation/             # Test results from different sources

- How should discovery findings be organized by domain (R1-R8)?
- How to prevent implementation agents from being confused by discovery notes?
- Best practices for specs/ that all agents need to read?

### 6. Anti-Patterns to Avoid
- Common mistakes in monorepo structure for AI agents
- What causes context pollution
- How to prevent agents from modifying the wrong files
- Security considerations for agent access

### 7. Tooling and Automation
- Git hooks for agent workflows
- CI/CD integration with agent-generated PRs
- Automated validation of agent outputs
- Monitoring agent effectiveness metrics

### 8. Scaling Considerations
- How to structure as we add more agents
- Managing 500+ BDD scenarios across domains
- Handling multiple client variations (Argus vs Nuanc)
- Performance optimization for large codebases

## Specific Questions to Answer

1. **Directory Naming**: What naming conventions help agents navigate efficiently?
   Example: Should we use `R1-SecurityAdmin/` or `security-admin/` or `domain-01-security/`?

2. **File Organization**: How to organize 586 BDD scenarios so agents can find relevant ones?
   - By feature? By domain? By priority?
   - How to link scenarios to implementation and test results?

3. **Cross-References**: Best practices for linking between:
   - BDD scenario → Implementation code
   - Discovery finding → Domain package
   - Test failure → Fix request

4. **Agent Instructions**: Where to place different types of instructions?
   - Global AGENTS.md vs subdirectory-specific
   - How to handle conflicting instructions
   - Templates for different agent types

5. **State Management**: How to track:
   - What each agent has completed
   - Which files are "owned" by which agent
   - Progress toward 95% coverage goal

## Expected Deliverables

1. **Monorepo Structure Template** optimized for AI agents
2. **AGENTS.md Templates** for different contexts
3. **.codexignore Patterns** for various agent workflows
4. **Naming Convention Guide** for maximum agent effectiveness
5. **Workflow Diagrams** showing agent interactions
6. **Troubleshooting Guide** for common issues
7. **Performance Metrics** for measuring agent effectiveness

## Repository Context

Current structure to analyze:
- 586 BDD scenarios across 42 feature files
- 8-10 domain packages (R1-R8+)
- 3 main agent types (discovery, implementation, validation)
- 2 deployment targets (Argus, Nuanc)
- Need to achieve 95% coverage efficiently

Please provide concrete examples and actual file structures, not just theoretical advice.

- How should discovery findings be organized by domain (R1-R8)?
- How to prevent implementation agents from being confused by discovery notes?
- Best practices for specs/ that all agents need to read?

### 6. Anti-Patterns to Avoid
- Common mistakes in monorepo structure for AI agents
- What causes context pollution
- How to prevent agents from modifying the wrong files
- Security considerations for agent access

### 7. Tooling and Automation
- Git hooks for agent workflows
- CI/CD integration with agent-generated PRs
- Automated validation of agent outputs
- Monitoring agent effectiveness metrics

### 8. Scaling Considerations
- How to structure as we add more agents
- Managing 500+ BDD scenarios across domains
- Handling multiple client variations (Argus vs Nuanc)
- Performance optimization for large codebases

## Specific Questions to Answer

1. **Directory Naming**: What naming conventions help agents navigate efficiently?
   Example: Should we use `R1-SecurityAdmin/` or `security-admin/` or `domain-01-security/`?

2. **File Organization**: How to organize 586 BDD scenarios so agents can find relevant ones?
   - By feature? By domain? By priority?
   - How to link scenarios to implementation and test results?

3. **Cross-References**: Best practices for linking between:
   - BDD scenario → Implementation code
   - Discovery finding → Domain package
   - Test failure → Fix request

4. **Agent Instructions**: Where to place different types of instructions?
   - Global AGENTS.md vs subdirectory-specific
   - How to handle conflicting instructions
   - Templates for different agent types

5. **State Management**: How to track:
   - What each agent has completed
   - Which files are "owned" by which agent
   - Progress toward 95% coverage goal

## Expected Deliverables

1. **Monorepo Structure Template** optimized for AI agents
2. **AGENTS.md Templates** for different contexts
3. **.codexignore Patterns** for various agent workflows
4. **Naming Convention Guide** for maximum agent effectiveness
5. **Workflow Diagrams** showing agent interactions
6. **Troubleshooting Guide** for common issues
7. **Performance Metrics** for measuring agent effectiveness

## Repository Context

Current structure to analyze:
- 586 BDD scenarios across 42 feature files
- 8-10 domain packages (R1-R8+)
- 3 main agent types (discovery, implementation, validation)
- 2 deployment targets (Argus, Nuanc)
- Need to achieve 95% coverage efficiently

Please provide concrete examples and actual file structures, not just theoretical advice.

## 