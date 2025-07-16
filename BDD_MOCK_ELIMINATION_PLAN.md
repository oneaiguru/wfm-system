# BDD Mock Data Elimination Plan

## 📊 Mock Usage Analysis

**Total Scenarios with Mocks**: 89 out of 580 (15.3%)
**High-Priority Mock Eliminations**: 47 scenarios affecting core business logic
**Low-Priority Mock Eliminations**: 42 scenarios affecting non-critical features

---

## 🚨 Priority 1: Critical Business Logic Mocks (Immediate Action Required)

### 1. Employee Request Status Tracking (12 scenarios affected)
**Files**: 02, 03, 04, 05
**Impact**: Core business process workflows broken

#### Current Mock Implementation:
```typescript
// src/ui/src/modules/employee-portal/components/requests/RequestManager.tsx
const mockStatusResponse = {
  status: "На рассмотрении", // Hardcoded Russian status
  timestamp: new Date().toISOString(),
  approver: "Mock Supervisor"
};
```

#### Problems:
- ❌ Status progression doesn't reflect real workflow
- ❌ No actual database persistence 
- ❌ Approval chains are simulated
- ❌ 1C ZUP integration claims false

#### Required Real Implementation:
```typescript
// services/requestStatusService.ts
export interface RequestStatusService {
  createRequest(requestData: RequestData): Promise<RequestResponse>;
  updateStatus(requestId: string, status: RequestStatus): Promise<void>;
  getStatusHistory(requestId: string): Promise<StatusHistory[]>;
  sendToApprover(requestId: string, approverId: string): Promise<void>;
}

// API Endpoints Required:
// POST /api/v1/requests - Create new request
// PUT /api/v1/requests/{id}/status - Update status
// GET /api/v1/requests/{id}/history - Get status history
// POST /api/v1/requests/{id}/approve - Approve request
```

#### Database Schema Required:
```sql
-- Real database tables needed
CREATE TABLE employee_requests (
  id UUID PRIMARY KEY,
  employee_id UUID NOT NULL,
  request_type VARCHAR(50) NOT NULL,
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE request_status_history (
  id UUID PRIMARY KEY,
  request_id UUID REFERENCES employee_requests(id),
  old_status VARCHAR(50),
  new_status VARCHAR(50),
  changed_by UUID NOT NULL,
  changed_at TIMESTAMP DEFAULT NOW(),
  comment TEXT
);

CREATE TABLE approval_workflow (
  id UUID PRIMARY KEY,
  request_id UUID REFERENCES employee_requests(id),
  approver_id UUID NOT NULL,
  approval_level INTEGER NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  approved_at TIMESTAMP
);
```

**Elimination Timeline**: 2-3 weeks
**Dependencies**: Database schema, approval workflow engine, 1C ZUP integration
**Risk Level**: **CRITICAL** - Core business functionality

---

### 2. Calendar Event Display (8 scenarios affected)
**Files**: 05, 14
**Impact**: Schedule management appears to work but shows fake data

#### Current Mock Implementation:
```typescript
// src/ui/src/modules/mobile-personal-cabinet/components/calendar/MobileCalendar.tsx
const mockCalendarEvents = [
  {
    date: "2025-06-15",
    shift: "9:00-17:00",
    type: "regular",
    status: "confirmed"
  }
  // ... hardcoded events
];
```

#### Problems:
- ❌ Calendar shows fake schedule data
- ❌ No real-time schedule updates
- ❌ Shift changes not reflected
- ❌ No integration with workforce planning

#### Required Real Implementation:
```typescript
// services/calendarService.ts
export interface CalendarService {
  getPersonalSchedule(employeeId: string, dateRange: DateRange): Promise<ScheduleEvent[]>;
  getShiftDetails(shiftId: string): Promise<ShiftDetail>;
  updateSchedulePreferences(preferences: SchedulePreference[]): Promise<void>;
  requestScheduleChange(changeRequest: ScheduleChangeRequest): Promise<void>;
}

// API Endpoints Required:
// GET /api/v1/schedules/personal/{employeeId} - Get personal schedule
// GET /api/v1/schedules/shifts/{shiftId} - Get shift details
// POST /api/v1/schedules/change-request - Request schedule change
// PUT /api/v1/schedules/preferences - Update preferences
```

**Elimination Timeline**: 1-2 weeks
**Dependencies**: Schedule management system, shift assignment algorithms
**Risk Level**: **HIGH** - Schedule visibility critical for operations

---

### 3. Performance Metrics Display (15 scenarios affected)
**Files**: 12, 15, 16
**Impact**: Management dashboards show fake performance data

#### Current Mock Implementation:
```typescript
// src/ui/src/services/apiIntegrationService.ts
const mockMetrics = {
  serviceLevel: 85.3, // Fake SLA performance
  agentsOnline: 25,   // Fake agent count
  callsInQueue: 12,   // Fake queue metrics
  avgWaitTime: 23     // Fake wait times
};
```

#### Problems:
- ❌ Management decisions based on fake metrics
- ❌ No real performance tracking
- ❌ SLA monitoring non-functional
- ❌ Operational insights missing

#### Required Real Implementation:
```typescript
// services/metricsService.ts
export interface MetricsService {
  getRealTimeMetrics(): Promise<OperationalMetrics>;
  getHistoricalMetrics(timeRange: TimeRange): Promise<HistoricalMetrics>;
  getAgentPerformance(agentId: string): Promise<AgentMetrics>;
  getSLACompliance(): Promise<SLAMetrics>;
}

// Real-time data collection required:
// - Call center integration for queue metrics
// - Agent status tracking for availability
// - Performance calculation algorithms
// - SLA threshold monitoring
```

**Elimination Timeline**: 3-4 weeks
**Dependencies**: Real-time data collection, metrics calculation engine, call center integration
**Risk Level**: **HIGH** - Business intelligence critical for operations

---

### 4. Supervisor Approval Workflows (8 scenarios affected)
**Files**: 02, 03, 13
**Impact**: Approval processes don't actually work end-to-end

#### Current Mock Implementation:
```typescript
// Supervisor approval simulation
const mockApprovalProcess = {
  autoApprove: true,
  approver: "Mock Supervisor",
  approvalTime: new Date(),
  comments: "Automatically approved for testing"
};
```

#### Problems:
- ❌ No real supervisor notification
- ❌ Approval routing doesn't work
- ❌ No approval delegation
- ❌ No audit trail

#### Required Real Implementation:
```typescript
// services/approvalService.ts
export interface ApprovalService {
  routeForApproval(requestId: string): Promise<ApprovalRouting>;
  submitApproval(approvalId: string, decision: ApprovalDecision): Promise<void>;
  delegateApproval(approvalId: string, delegateToId: string): Promise<void>;
  escalateOverdueApproval(approvalId: string): Promise<void>;
}

// Notification system required:
// - Email notifications to supervisors
// - In-app approval queues
// - Escalation timers
// - Approval delegation chains
```

**Elimination Timeline**: 2-3 weeks
**Dependencies**: Notification system, approval routing engine, user management
**Risk Level**: **HIGH** - Approval workflows essential for business operations

---

## 🟡 Priority 2: Feature Enhancement Mocks (Medium Priority)

### 5. Biometric Authentication (6 scenarios affected)
**File**: 14
**Impact**: Mobile security features non-functional

#### Current Mock Implementation:
```typescript
// Mobile biometric setup simulation
const mockBiometricSetup = {
  available: true,
  enrolled: false,
  supportedTypes: ["fingerprint", "face"]
};
```

#### Options for Elimination:
**Option A: Real Biometric Integration**
- WebAuthn API integration
- Native mobile biometric APIs
- Secure key storage implementation
- Timeline: 2-3 weeks

**Option B: Feature Removal**
- Remove biometric claims from UI
- Update BDD scenarios to remove biometric requirements
- Focus on standard authentication
- Timeline: 1 week

**Recommendation**: Option B (Feature Removal)
**Risk Level**: **MEDIUM** - Nice-to-have feature, not critical

---

### 6. Real-time Synchronization Status (5 scenarios affected)
**Files**: 11, 15
**Impact**: Integration monitoring appears functional but isn't

#### Current Mock Implementation:
```typescript
// Sync status simulation
const mockSyncStatus = {
  lastSync: new Date(),
  status: "success",
  recordsProcessed: 1250,
  errors: []
};
```

#### Required Real Implementation:
- Real-time sync job monitoring
- Error logging and retry mechanisms
- Performance metrics collection
- Integration health checks

**Elimination Timeline**: 2-3 weeks
**Dependencies**: Background job system, logging infrastructure
**Risk Level**: **MEDIUM** - Important for system monitoring

---

## 🔧 Priority 3: UI Enhancement Mocks (Lower Priority)

### 7. Chart Data Visualization (12 scenarios affected)
**Files**: 08, 09, 12, 15
**Impact**: Reports and analytics show fake trends

#### Current Mock Implementation:
```typescript
// Chart data simulation
const mockChartData = {
  labels: ["Mon", "Tue", "Wed", "Thu", "Fri"],
  datasets: [{
    data: [65, 59, 80, 81, 56] // Fake trend data
  }]
};
```

#### Required Real Implementation:
- Historical data aggregation
- Real-time data feeds for charts
- Configurable time ranges
- Export functionality

**Elimination Timeline**: 1-2 weeks
**Dependencies**: Data aggregation service, export functionality
**Risk Level**: **LOW** - Visualization quality improvement

---

### 8. Notification Systems (8 scenarios affected)
**Files**: 14, 15, 18
**Impact**: User notifications don't actually deliver

#### Current Mock Implementation:
```typescript
// Notification simulation
const mockNotifications = [
  {
    id: "1",
    title: "Mock Notification",
    message: "This is a test notification",
    timestamp: new Date(),
    read: false
  }
];
```

#### Required Real Implementation:
- Real notification delivery system
- Push notification infrastructure
- Email notification integration
- In-app notification management

**Elimination Timeline**: 2-3 weeks
**Dependencies**: Notification infrastructure, email service integration
**Risk Level**: **LOW** - User experience enhancement

---

## 📋 Implementation Roadmap

### Phase 1: Critical Business Logic (Weeks 1-4)
**Total Scenarios**: 28 high-priority mocks

#### Week 1-2: Request Workflow Foundation
- ✅ Implement real request status tracking
- ✅ Build approval workflow engine  
- ✅ Create database schema for requests
- ✅ Integrate supervisor notification system

#### Week 3-4: Schedule & Performance Data
- ✅ Implement real calendar integration
- ✅ Build performance metrics collection
- ✅ Create real-time data feeds
- ✅ Integrate with call center systems

### Phase 2: System Integration (Weeks 5-7)
**Total Scenarios**: 19 medium-priority mocks

#### Week 5-6: Real-time Synchronization
- ✅ Implement background sync jobs
- ✅ Build error logging and retry systems
- ✅ Create integration health monitoring
- ✅ Add performance metrics collection

#### Week 7: Feature Decision & Implementation
- ✅ Decide on biometric authentication (recommend removal)
- ✅ Implement notification delivery system
- ✅ Complete integration monitoring

### Phase 3: UI Enhancement (Weeks 8-10)
**Total Scenarios**: 20 lower-priority mocks

#### Week 8-9: Data Visualization
- ✅ Implement real chart data feeds
- ✅ Build historical data aggregation
- ✅ Add configurable reporting
- ✅ Create export functionality

#### Week 10: Final Mock Elimination
- ✅ Replace remaining UI mocks
- ✅ Comprehensive testing of real data flows
- ✅ Documentation updates
- ✅ User training materials

---

## 🛠️ Technical Implementation Strategy

### Database Schema Updates Required:
```sql
-- Core request management
CREATE TABLE employee_requests (/*...*/);
CREATE TABLE request_status_history (/*...*/);
CREATE TABLE approval_workflow (/*...*/);

-- Schedule management
CREATE TABLE employee_schedules (/*...*/);
CREATE TABLE schedule_changes (/*...*/);
CREATE TABLE schedule_preferences (/*...*/);

-- Performance metrics
CREATE TABLE operational_metrics (/*...*/);
CREATE TABLE agent_performance (/*...*/);
CREATE TABLE sla_tracking (/*...*/);

-- Notification system
CREATE TABLE notifications (/*...*/);
CREATE TABLE notification_delivery (/*...*/);
```

### API Endpoints Required:
```typescript
// Request management
POST /api/v1/requests
PUT /api/v1/requests/{id}/status
GET /api/v1/requests/{id}/history
POST /api/v1/requests/{id}/approve

// Schedule management  
GET /api/v1/schedules/personal/{employeeId}
POST /api/v1/schedules/change-request
PUT /api/v1/schedules/preferences

// Performance metrics
GET /api/v1/metrics/realtime
GET /api/v1/metrics/historical
GET /api/v1/metrics/sla

// Notifications
GET /api/v1/notifications/{userId}
POST /api/v1/notifications/send
PUT /api/v1/notifications/{id}/read
```

### External Integration Requirements:
- **Call Center Integration**: Real-time queue metrics, agent status
- **1C ZUP Integration**: Employee data, payroll information
- **Email Service**: Notification delivery
- **Background Job System**: Scheduled tasks, data processing

---

## 📊 Success Metrics

### Immediate Goals (4 weeks):
- [ ] **Zero mock data** in core business workflows (28 scenarios)
- [ ] **Real request workflows** functioning end-to-end
- [ ] **Actual calendar data** displayed in all interfaces
- [ ] **Real performance metrics** in dashboards

### Medium-term Goals (7 weeks):
- [ ] **80% mock elimination** (71/89 scenarios)
- [ ] **Real-time data** in all monitoring interfaces
- [ ] **Functional notification system**
- [ ] **Integration health monitoring**

### Long-term Goals (10 weeks):
- [ ] **100% mock elimination** (89/89 scenarios)
- [ ] **All data flows verified** with real backend systems
- [ ] **Comprehensive testing** with real data
- [ ] **Production-ready quality** across all features

---

## 🎯 Quality Assurance

### Verification Process:
1. **Code Review**: Ensure all mock references removed
2. **Database Verification**: Confirm real data persistence
3. **Integration Testing**: Validate external system connections
4. **User Acceptance Testing**: Verify workflows with real users
5. **Performance Testing**: Ensure real data doesn't degrade performance

### Risk Mitigation:
- **Gradual Rollout**: Replace mocks incrementally
- **Fallback Mechanisms**: Maintain error handling for external system failures
- **Data Validation**: Ensure data quality in real implementations
- **Monitoring**: Track system performance during transition

---

**Analysis Date**: $(date)
**Next Review**: Weekly progress assessment during elimination phases
**Methodology**: Code inspection + mock usage tracking + risk assessment