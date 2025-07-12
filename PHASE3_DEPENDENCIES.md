# Phase 3 Dependency Matrix 📊

## Executive Summary
This document maps all cross-agent dependencies and blocking issues identified from Phase 2 PRDs. Critical path items are marked with 🔴, high priority with 🟡, and completed items with ✅.

## Agent Dependency Matrix

### 1. ALGORITHM-OPUS → UI-OPUS Dependencies

| Algorithm Component | UI Interface Needed | Priority | Status | Blocking Issue |
|-------------------|-------------------|----------|---------|----------------|
| Real-time Erlang C | Live capacity dashboard | 🔴 CRITICAL | ❌ Not Started | WebSocket infrastructure |
| Multi-Channel Models | Channel selector widget | 🔴 CRITICAL | ❌ Not Started | UI component spec needed |
| Forecast Accuracy (MAPE/WAPE) | Accuracy metrics display | 🟡 HIGH | ❌ Not Started | Chart library selection |
| Schedule Scorer | Schedule quality viewer | 🟡 HIGH | ❌ Not Started | Score visualization design |
| Cost Optimizer | Cost analysis dashboard | 🟡 HIGH | ❌ Not Started | Financial data display |
| Outlier Detection | Alert notification system | 🟡 HIGH | ❌ Not Started | Notification framework |
| Load Deviation Monitor | Real-time deviation chart | 🟡 HIGH | ❌ Not Started | Streaming data display |
| Multi-Skill LP | Skill assignment grid | ✅ COMPLETE | ✅ Done | None |
| Genetic Algorithm | Shift pattern viewer | ✅ COMPLETE | ✅ Done | None |

### 2. DATABASE-OPUS → INTEGRATION-OPUS Dependencies

| DB Schema | API Endpoints Needed | Priority | Status | Blocking Issue |
|-----------|---------------------|----------|---------|----------------|
| Forecasting Schema | 25 CRUD endpoints | 🔴 CRITICAL | ❌ Not Started | Schema not finalized |
| Schedule Management | 35 endpoints + WebSocket | 🔴 CRITICAL | ❌ Not Started | Complex state management |
| Real-time Monitoring | 5 SSE streams + 15 endpoints | 🔴 CRITICAL | ❌ Not Started | Streaming infrastructure |
| Reporting Framework | 30 analytics endpoints | 🟡 HIGH | ❌ Not Started | Query optimization needed |
| Integration Management | 44 external API endpoints | 🟡 HIGH | ❌ Not Started | 1C ZUP documentation |
| Quality Management | 10 QA endpoints | 🟢 MEDIUM | ❌ Not Started | Requirements unclear |
| Time-Series Data | 20 endpoints | ✅ COMPLETE | ✅ Done | None |
| Organization/RBAC | 40 admin endpoints | ✅ COMPLETE | ✅ Done | None |

### 3. UI-OPUS → INTEGRATION-OPUS Dependencies

| UI Component | API Calls Required | Priority | Status | Blocking Issue |
|-------------|-------------------|----------|---------|----------------|
| Vacancy Planning Module | POST /vacancies, GET /staffing-gaps | 🔴 CRITICAL | ❌ Not Started | API spec missing |
| Personnel Scheduling Grid | WebSocket /schedule-updates | 🔴 CRITICAL | ❌ Not Started | Real-time sync protocol |
| Analytics Dashboard | GET /analytics/*, SSE streams | 🔴 CRITICAL | ❌ Not Started | Data aggregation API |
| Import/Export Module | POST /import, GET /export/* | 🟡 HIGH | ❌ Not Started | File handling API |
| Routing Rules Config | CRUD /routing-rules/* | 🟡 HIGH | ❌ Not Started | Complex validation |
| Mobile App | 35 mobile-optimized endpoints | 🟡 HIGH | ❌ Not Started | Mobile API gateway |
| Historical Data Tab | GET /historical/* | ✅ COMPLETE | ✅ Done | None |
| Forecast Tab | GET /forecasts/* | ✅ COMPLETE | ✅ Done | None |

### 4. Cross-Agent Blocking Issues

| Issue | Affects | Impact | Resolution Path | Owner |
|-------|---------|--------|----------------|-------|
| WebSocket Infrastructure | ALL | 🔴 CRITICAL | INT must implement first | INTEGRATION-OPUS |
| Database Schema Completion | INT, UI | 🔴 CRITICAL | DB must finalize 6 schemas | DATABASE-OPUS |
| 1C ZUP Documentation | DB, INT, AL | 🔴 CRITICAL | External dependency | Project Manager |
| Real-time Data Streaming | AL, UI | 🔴 CRITICAL | Need architecture decision | All Agents |
| Algorithm Service Architecture | INT, UI | 🟡 HIGH | AL must define interfaces | ALGORITHM-OPUS |
| Mobile API Gateway | UI, INT | 🟡 HIGH | Needs security design | INTEGRATION-OPUS |
| Forecast Storage Schema | AL, DB | 🟡 HIGH | Joint design session needed | DB + AL |
| Performance Testing Framework | ALL | 🟡 HIGH | Unified approach needed | All Agents |

## Phase 3 Implementation Order

Based on dependency analysis, here's the recommended implementation sequence:

### Sprint 1-2 (Weeks 1-4): Foundation
1. **INTEGRATION-OPUS**: WebSocket infrastructure (unblocks all real-time features)
2. **DATABASE-OPUS**: Forecasting & calculation schemas (unblocks 25 API endpoints)
3. **ALGORITHM-OPUS**: Real-time Erlang C service definition (unblocks UI dashboard)

### Sprint 3-4 (Weeks 5-8): Core Features
1. **DATABASE-OPUS**: Schedule management tables (unblocks 35 endpoints)
2. **INTEGRATION-OPUS**: Complete CRUD APIs for new schemas
3. **UI-OPUS**: Vacancy Planning Module (using new APIs)
4. **ALGORITHM-OPUS**: Multi-channel models implementation

### Sprint 5-6 (Weeks 9-12): Advanced Features
1. **DATABASE-OPUS**: Real-time monitoring infrastructure
2. **INTEGRATION-OPUS**: SSE streams and monitoring APIs
3. **UI-OPUS**: Personnel Scheduling Grid with WebSocket
4. **ALGORITHM-OPUS**: Forecast accuracy metrics

### Sprint 7-8 (Weeks 13-16): Integration & Polish
1. **INTEGRATION-OPUS**: External system connectors (1C ZUP, LDAP)
2. **UI-OPUS**: Analytics Dashboard and Mobile App
3. **ALGORITHM-OPUS**: Cost optimization and advanced algorithms
4. **DATABASE-OPUS**: Reporting framework completion

## Critical Success Factors

1. **Daily Sync Meetings**: Cross-agent coordination on blocking issues
2. **Shared Interface Definitions**: All agents must agree on data contracts
3. **Parallel Development**: Use subagents to work on non-blocking items
4. **Integration Testing**: Continuous validation of cross-agent interfaces
5. **Performance Monitoring**: Maintain <10ms query and <100ms API targets

## Risk Mitigation

| Risk | Impact | Mitigation Strategy |
|------|--------|-------------------|
| 1C ZUP documentation delay | HIGH | Build mock interface, update later |
| WebSocket complexity | HIGH | Consider fallback polling mechanism |
| Schema changes | MEDIUM | Version APIs, maintain backwards compatibility |
| Performance degradation | MEDIUM | Implement caching layer early |
| Mobile API differences | LOW | Design mobile-first, adapt for web |

## Metrics for Success

- 🎯 **All blocking dependencies resolved**: Within first 4 weeks
- 🎯 **API coverage**: 95% of 220 endpoints implemented
- 🎯 **Integration tests**: 100% cross-agent interfaces tested
- 🎯 **Performance SLAs**: Maintained throughout Phase 3
- 🎯 **BDD compliance**: 95% of scenarios passing

## Next Steps

1. **Project Manager**: Schedule cross-agent sync meeting
2. **Each Agent**: Review dependencies and confirm timelines
3. **INTEGRATION-OPUS**: Begin WebSocket infrastructure immediately
4. **DATABASE-OPUS**: Finalize forecasting schema within 48 hours
5. **All Agents**: Define shared data contracts by end of week 1

---

*Document Version: 1.0*  
*Created: Phase 3 Planning*  
*Last Updated: Post-Phase 2 Analysis*