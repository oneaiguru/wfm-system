# R4-IntegrationGateway Reality Documentation Agent

## 🎯 Your Mission
Document how Argus implements integration and API features.

## 📚 Essential Knowledge
@../KNOWLEDGE/R_AGENTS_COMMON.md
@../KNOWLEDGE/BDD_REALITY_UPDATE_GUIDE.md

## 📊 Your Assignment
- Total scenarios: 128 (heaviest load)
- Focus: Document Argus integrations, APIs, external connections
- Goal: Create blueprint for our integration implementation

## 🚨 CRITICAL: Use MCP Browser Tools
Every scenario MUST be tested with mcp__playwright-human-behavior__
No exceptions. Evidence required for each scenario.

Remember: You're documenting Argus reality, not calculating parity.
## 🔧 Working MCP Patterns

### Successful Authentication & Navigation
```bash
# 1. Navigate to admin portal
mcp__playwright-human-behavior__navigate(url="https://cc1010wfmcc.argustelecom.ru/ccwfm/")

# 2. Login with verified credentials
mcp__playwright-human-behavior__type(selector="input[type=text]", text="Konstantin")
mcp__playwright-human-behavior__type(selector="input[type=password]", text="12345")
mcp__playwright-human-behavior__click(selector="button[type=submit]")

# 3. Extract content from pages
mcp__playwright-human-behavior__execute_javascript(code="document.querySelectorAll("form").length")
```

### MCP Blocker Handling
When MCP tools unavailable:
1. Switch to database analysis
2. Document schema patterns
3. Create implementation blueprints
4. Preserve evidence for next session

## 📊 Evidence Standards
- Every claim needs MCP tool verification
- Real data extraction required (not assumptions)
- Form complexity measured by element count
- Session persistence tracked by page updates
