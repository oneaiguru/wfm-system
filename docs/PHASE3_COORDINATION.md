# Phase 3 Algorithm Coordination Plan

## Executive Summary

This document outlines the coordination requirements between ALGORITHM-OPUS and other agents for successful Phase 3 implementation. Critical dependencies have been identified that could block real-time algorithm development.

## Critical Path Dependencies 🚨

### 1. WebSocket Infrastructure (Blocks ALL Real-time)
**Owner**: INTEGRATION-OPUS
**Needed by**: Week 1 of Phase 3
**What AL needs**:
```javascript
// WebSocket connection for real-time updates
ws.on('queue_state_change', (data) => {
  // Trigger real-time Erlang C recalculation
  const newStaffing = calculateRealTimeErlang(data);
  ws.emit('staffing_update', newStaffing);
});
```

**Without this**: No real-time algorithms can function

### 2. Real-time Data Streaming
**Owner**: DATABASE-OPUS  
**Needed by**: Week 1 of Phase 3
**What AL needs**:
```sql
-- Streaming query for queue metrics
SELECT queue_id, calls_waiting, agents_available, 
       avg_wait_time, service_level
FROM real_time_queue_stats
WHERE last_update > NOW() - INTERVAL '5 seconds';
```

**Without this**: Must use batch processing (30-60 second delays)

### 3. Forecast Storage Schema
**Owner**: DATABASE-OPUS
**Needed by**: Week 3 of Phase 3
**What AL needs**:
```sql
CREATE TABLE forecasts (
  id SERIAL PRIMARY KEY,
  queue_id VARCHAR(50),
  forecast_date DATE,
  interval_hour INTEGER,
  forecast_value DECIMAL(10,2),
  actual_value DECIMAL(10,2),
  created_at TIMESTAMP,
  model_version VARCHAR(50)
);

CREATE TABLE accuracy_metrics (
  id SERIAL PRIMARY KEY,
  forecast_id INTEGER REFERENCES forecasts(id),
  mape DECIMAL(5,2),
  wape DECIMAL(5,2),
  bias DECIMAL(5,2)
);
```

**Without this**: Cannot track algorithm performance

## Integration Contracts

### AL → INT → UI: Real-time Staffing Updates
```typescript
interface StaffingUpdate {
  timestamp: string;
  queue_id: string;
  current_staff: number;
  required_staff: number;
  service_level: number;
  recommendations: {
    action: 'add_staff' | 'reduce_staff' | 'maintain';
    urgency: 'low' | 'medium' | 'high' | 'critical';
    agents_needed: number;
  };
}
```

### DB → AL: Queue State Stream
```typescript
interface QueueState {
  queue_id: string;
  timestamp: string;
  metrics: {
    calls_offered: number;
    calls_waiting: number;
    calls_abandoned: number;
    agents_logged_in: number;
    agents_available: number;
    agents_on_call: number;
    avg_handle_time: number;
    avg_wait_time: number;
    service_level_pct: number;
  };
}
```

### AL → INT → 1C: Time Code Export
```typescript
interface TimeCodeRecord {
  employee_id: string;
  date: string;
  shifts: Array<{
    start_time: string;
    end_time: string;
    time_code: 'I' | 'H' | 'C' | 'RV';
    hours: number;
    rate_multiplier: number;
  }>;
}
```

## Coordination Timeline

### Week 1: Foundation
- [ ] INT: Setup WebSocket infrastructure
- [ ] DB: Create real-time views/triggers
- [ ] AL: Implement real-time Erlang C calculator
- [ ] All: Test end-to-end real-time flow

### Week 2: Streaming
- [ ] DB: Implement change data capture
- [ ] INT: Create event bus for updates
- [ ] AL: Connect to event streams
- [ ] UI: Build real-time dashboard components

### Week 3: Analytics
- [ ] DB: Create forecast/accuracy schema
- [ ] AL: Implement MAPE/WAPE calculators
- [ ] UI: Create accuracy visualizations
- [ ] All: Integration testing

### Week 4: Advanced Features
- [ ] INT: 1C ZUP adapter development
- [ ] AL: Multi-channel Erlang variants
- [ ] DB: Historical data API optimization
- [ ] UI: Schedule optimization interface

## Communication Protocol

### Daily Standups
```
Time: 10:00 AM
Format: 15 minutes
Topics:
- Blockers
- Integration points
- API contract changes
```

### Weekly Integration Reviews
```
Time: Fridays 2:00 PM
Format: 1 hour
Topics:
- End-to-end testing
- Performance metrics
- Next week planning
```

### Escalation Path
1. Technical blockers → Tech Lead
2. Resource conflicts → Project Manager
3. Scope changes → Product Owner

## Success Metrics

### Week 1 Targets
- WebSocket latency: <100ms
- Real-time calculation: <50ms
- End-to-end update: <200ms

### Week 2 Targets
- Stream reliability: 99.9%
- Event processing: <10ms
- Dashboard refresh: <1 second

### Week 3 Targets
- Forecast storage: <100ms writes
- MAPE calculation: <500ms
- Accuracy reports: <2 seconds

### Week 4 Targets
- 1C export: <5 seconds
- Multi-channel optimization: <1 second
- Historical queries: <500ms

## Fallback Plans

### If WebSockets Delayed
- Use HTTP polling (5-second intervals)
- Implement SSE as alternative
- Cache aggressively

### If Real-time DB Delayed  
- Batch process every 30 seconds
- Use materialized views
- Pre-aggregate common queries

### If 1C Integration Blocked
- Build file-based export
- Create manual upload interface
- Document format for client

## Action Items

### For ALGORITHM-OPUS
1. Prepare WebSocket client code
2. Define exact data requirements
3. Create integration test suite

### For DATABASE-OPUS
1. Design real-time schema
2. Setup CDC/triggers
3. Optimize query performance

### For INTEGRATION-OPUS
1. Implement WebSocket server
2. Create event bus
3. Build 1C adapter

### For UI-OPUS
1. Design real-time components
2. Implement update handlers
3. Create performance monitors

## Conclusion

Phase 3 success depends on tight coordination between agents. The critical path runs through WebSocket infrastructure and real-time data streaming. With proper coordination and fallback plans, we can deliver revolutionary real-time workforce optimization capabilities.