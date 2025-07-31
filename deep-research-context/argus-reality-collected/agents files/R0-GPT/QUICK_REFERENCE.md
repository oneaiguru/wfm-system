# Quick Reference

## System Access
```bash
# Our System
URL: http://localhost:3000
Login: admin/password or john.doe/test

# Argus (403 blocked - need human-behavior MCP)
Admin: https://cc1010wfmcc.argustelecom.ru/ccwfm/ (Konstantin/12345)
Employee: https://lkcc1010wfmcc.argustelecom.ru/ (test/test)
```

## MCP Tools
- ❌ playwright-human-behavior NOT available to sub-agents
- ❌ playwright-official NOT available to sub-agents
- ✅ Focus on code analysis, not web exploration

## Critical References for Success
- Integration Patterns: `/agents/BDD-SCENARIO-AGENT-2/INTEGRATION_PATTERNS_LIBRARY_UPDATED.md`
- UI Priority Map: `/agents/BDD-UI-PRIORITIZATION/BDD_UI_MAPPING.md`
- Journey Analysis: `/agents/BDD-SCENARIO-AGENT-2/VACATION_JOURNEY_COMPLETE.md`
- Argus Docs: `/intelligence/argus/docs-consolidated/База знаний WFM CC/Документация_numbered/`

## Key Patterns
1. Route Mismatch: Add specific routes or update tests
2. Form Accessibility: Add name attributes
3. Test IDs: Add data-testid for e2e testing
4. Terminology: Argus uses Russian terms, we use English

## Priority Order (Demo Value 5)
1. System Architecture (70% done)
2. Employee Requests (40% done)
3. Forecasting (60% done)
4. Schedule Planning (20% done)
5. Mobile (35% done)