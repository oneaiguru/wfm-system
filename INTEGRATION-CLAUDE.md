# INTEGRATION-CLAUDE.md - System Integration Map

## Component Connections

### Core Data Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Database  │────▶│     API     │────▶│     UI      │
│ PostgreSQL  │◀────│   FastAPI   │◀────│    React    │
└─────────────┘     └─────────────┘     └─────────────┘
       │                    │                    │
       │                    ▼                    │
       │            ┌─────────────┐             │
       └───────────▶│  Algorithms │◀────────────┘
                    │   Python    │
                    └─────────────┘
```

### Integration Architecture
```
External Systems                 WFM Core                    Client Layer
┌──────────────┐          ┌──────────────────┐         ┌──────────────┐
│  Argus WFM   │─────────▶│                  │         │  Web Client  │
├──────────────┤          │                  │         ├──────────────┤
│   1C:ZUP     │◀────────▶│   Integration    │◀───────▶│ Mobile Client│
├──────────────┤          │     Layer        │         ├──────────────┤
│Contact Center│─────────▶│                  │         │  API Client  │
├──────────────┤          │                  │         └──────────────┘
│   WebStats   │─────────▶│                  │                ▲
├──────────────┤          └──────────────────┘                │
│     OKK      │                   │                          │
└──────────────┘                   ▼                          │
                          ┌──────────────────┐                │
                          │   Message Bus    │────────────────┘
                          │     (Kafka)      │
                          └──────────────────┘
```

## Data Flow Paths

### 1. Forecast Flow
```
Historical Data → Database → API → Algorithm Service → ML Models
    ↓                                      ↓
UI Display ← WebSocket ← API ← ← ← ← Forecast Results
```

### 2. Schedule Generation Flow
```
1. Forecast Data + Constraints → Genetic Algorithm
2. Algorithm → Candidate Schedules → Scoring Engine
3. Best Schedule → Database → API → UI Display
4. UI Edits → API → Database → Recalculation
```

### 3. Real-time Monitoring Flow
```
Contact Center → WebSocket → API → Database (Queue Metrics)
                    ↓
            UI Dashboard ← 30-second updates
                    ↓
            Alert System → Notifications
```

### 4. Integration Sync Flow
```
1C:ZUP → API Adapter → Transformation → WFM Database
  ↑                                          ↓
  └──────── Bidirectional Sync ←────────────┘
```

## Missing Integrations

### High Priority
1. **OKK System Integration**
   - Status: Not started
   - Required for: Client compliance
   - Complexity: Medium
   - Timeline: 2 weeks

2. **Advanced Mobile Sync**
   - Status: Basic implementation
   - Required for: Offline mode
   - Complexity: High
   - Timeline: 3 weeks

3. **SSO/LDAP Integration**
   - Status: Planned
   - Required for: Enterprise deployment
   - Complexity: Medium
   - Timeline: 1 week

### Medium Priority
4. **Email/SMS Gateway**
   - Status: Not implemented
   - Required for: Notifications
   - Complexity: Low
   - Timeline: 3 days

5. **BI Tool Connectors**
   - Status: Not implemented
   - Required for: Advanced analytics
   - Complexity: Medium
   - Timeline: 2 weeks

6. **HR System Integration**
   - Status: Not implemented
   - Required for: Employee data sync
   - Complexity: High
   - Timeline: 4 weeks

### Low Priority
7. **Voice Assistant**
   - Status: Research phase
   - Required for: Future enhancement
   - Complexity: Very High
   - Timeline: 6-8 weeks

## Integration Endpoints

### Inbound Integrations
```yaml
/api/v1/integrations/:
  /argus:
    - /import/historical
    - /import/employees
    - /import/schedules
  
  /onec:
    - /sync/employees
    - /sync/timecodes
    - /sync/payroll
  
  /contact-center:
    - /realtime/calls
    - /realtime/agents
    - /historical/metrics
```

### Outbound Integrations
```yaml
Webhooks:
  - Schedule Published
  - Forecast Completed
  - Alert Triggered
  - Approval Required
  
API Calls:
  - 1C:ZUP time codes
  - Argus compatibility
  - Email notifications
  - SMS alerts
```

## Integration Health

### Current Status
| Integration | Status | Health | Last Sync |
|------------|--------|---------|-----------|
| Argus Import | ✅ Active | 🟢 100% | 2 min ago |
| 1C:ZUP Sync | ✅ Active | 🟡 85% | 15 min ago |
| Contact Center | ✅ Active | 🟢 99% | Real-time |
| WebStats | ⚠️ Partial | 🟡 70% | 1 hour ago |
| OKK System | ❌ Pending | 🔴 0% | Never |

### Performance Metrics
- **Argus Import**: 10K records/min
- **1C Sync**: 500 employees/min
- **WebSocket**: 1000 concurrent connections
- **Webhook Delivery**: 99.8% success rate

## Quick Commands

### Test Integrations
```bash
# Test Argus connection
curl -X POST http://localhost:8000/api/v1/integrations/argus/test

# Test 1C:ZUP sync
python test_integrations.py --system=1c_zup

# Monitor WebSocket connections
wscat -c ws://localhost:8000/api/v1/ws/monitor
```

### Debug Integration Issues
```bash
# Check integration logs
tail -f logs/integration.log | grep ERROR

# Verify message queue
kafka-console-consumer --topic wfm-events --from-beginning

# Test webhook delivery
curl -X POST http://localhost:8000/api/v1/webhooks/test
```

## Next Steps

1. **Complete OKK Integration**
   - Define API contract
   - Build adapter
   - Test bidirectional sync

2. **Enhance Mobile Sync**
   - Implement conflict resolution
   - Add offline queue
   - Build sync UI

3. **Add Monitoring**
   - Integration dashboard
   - Health checks
   - Alert rules

4. **Security Hardening**
   - API rate limiting
   - Request signing
   - Audit logging