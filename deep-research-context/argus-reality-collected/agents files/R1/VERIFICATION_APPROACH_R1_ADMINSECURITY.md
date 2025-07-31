# R1 (R-AdminSecurity) Verification Approach

**Agent**: R1 - R-AdminSecurity  
**Domain**: Admin & Security (95 scenarios, 5 demo-critical)  
**Date**: 2025-07-26  
**Status**: Ready for verification (Argus servers currently down)

## 🎯 My Mission
Verify authentication, authorization, user management, and security scenarios against Argus system using MCP browser automation.

## 📊 Scenario Overview
- **Total Scenarios**: 95
- **Demo-Critical**: 5 (demo_value: 5)
- **Priority Features**: Auth, roles, SSO, user management, audit

## 🔧 Technical Setup

### MCP Browser Configuration
- **Tool**: `mcp__playwright-human-behavior__` (for Argus anti-bot handling)
- **Primary URL**: https://lkcc1010wfmcc.argustelecom.ru/
- **Admin URL**: https://cc1010wfmcc.argustelecom.ru/ccwfm/
- **Credentials**: 
  - Employee: test/test
  - Admin: Konstantin/12345

### Key Scenarios to Start With
From registry analysis, starting with:

1. **SPEC-001**: System roles configuration (demo_value: 3)
2. **SPEC-002**: Business role creation (demo_value: 3) 
3. **SPEC-003**: Access rights assignment (demo_value: 3)

## 🚀 Verification Process

### Phase 1: Authentication Foundation
1. Basic login flow verification
2. SSO authentication paths
3. Session management
4. Password policies

### Phase 2: Authorization & Roles
1. Role creation and assignment
2. Permission verification
3. Access control testing
4. Role hierarchy validation

### Phase 3: User Management
1. User CRUD operations
2. Profile management
3. Bulk operations
4. Audit trail verification

## 📋 Expected Patterns
Based on integration patterns library:
- **Pattern 4**: Admin route separation
- **Pattern 9**: Session management
- Route granularity mismatches
- Form field accessibility issues

## ✅ Success Criteria
- Document reality match percentage for each scenario
- Tag scenarios with @verified when complete
- Create test users for other domains
- Establish authentication foundation for R2-R8

## 🔄 Dependencies
- **I provide to**: ALL other R-agents (foundational auth)
- **Must run first**: Day 1 priority
- **Blocks**: All other domain verifications until auth works

## 📝 Current Status
- ✅ Domain discovery complete
- ✅ Registry access established  
- 🔄 Awaiting Argus server access
- ⏳ Ready to begin verification sequence

**Next**: Start verification as soon as Argus servers are accessible.