# BDD Scenario Execution Order & Dependencies

## 🎯 Purpose
This index defines the execution order for BDD scenarios to ensure:
1. Dependencies are built before dependents
2. Authentication/core features are ready first
3. Agents work sequentially, not in parallel chaos
4. No duplication of effort

## 📋 Execution Phases

### Phase 1: Core Infrastructure (MUST DO FIRST)
**Goal**: Authentication and basic system access

1. **01-system-architecture.feature**
   - Scenario: Access Administrative System (AUTH ENDPOINTS)
   - Scenario: Limited Permissions (ROLES/PERMISSIONS)
   - Owner: INTEGRATION-OPUS + DATABASE-OPUS

### Phase 2: Employee Foundation
**Goal**: Basic employee functionality

2. **02-employee-requests.feature**
   - Scenario: Create Request for Time Off
   - Scenario: Request Status Tracking
   - Owner: ALL AGENTS (Database → API → UI → Test)

3. **14-mobile-personal-cabinet.feature** 
   - Scenario: Employee views personal schedule
   - Scenario: Mobile schedule access
   - Owner: UI-OPUS + INTEGRATION-OPUS

### Phase 3: Manager Features
**Goal**: Approval workflows

4. **03-complete-business-process.feature**
   - Scenario: Supervisor Approve Time Off
   - Scenario: Manager approval workflow
   - Owner: ALGORITHM-OPUS + INTEGRATION-OPUS

### Phase 4: Advanced Features
**Goal**: Complex functionality (ONLY after 1-3 work)

5. **08-load-forecasting-demand-planning.feature**
   - Scenario: Erlang C calculations
   - Owner: ALGORITHM-OPUS

6. **10-monthly-intraday-activity-planning.feature**
   - Scenario: Schedule generation
   - Owner: ALGORITHM-OPUS + DATABASE-OPUS

## 🚨 CRITICAL RULES

1. **NO AGENT** starts Phase 2 until Phase 1 is complete
2. **SEARCH FIRST** - Check existing assets before building
3. **SEQUENTIAL** - Complete current phase before moving to next
4. **COORDINATE** - If blocked, help unblock other agents

## 📊 Current Status (Updated: 2025-07-19)

### Phase 1 Status:
- [ ] Auth endpoints (BLOCKING EVERYTHING!)
- [ ] Permission system
- [ ] Basic database schema

### Phase 2 Status:
- [ ] Employee request creation
- [ ] Personal schedule view
- [ ] Mobile access

### Phase 3 Status:
- [ ] Approval workflows
- [ ] Manager dashboards

## 🎯 Next Actions

1. **INTEGRATION-OPUS**: Drop everything, implement auth endpoints
2. **DATABASE-OPUS**: Ensure auth tables exist (users, sessions, permissions)
3. **Others**: WAIT for Phase 1 completion

---
*This execution order is MANDATORY. Random task selection will cause chaos.*