# 🔗 Complete UI ↔ API Integration Guide

## 📊 Overview: 40+ UI Components → 517 API Endpoints

This guide maps every UI component to its required API endpoints for systematic integration testing.

## 🧪 Integration Testing Process

### Step 1: Use the Integration Tester
```bash
# Navigate to: http://localhost:3000/integration-tester
# This tool automatically tests all connections
```

### Step 2: Component-by-Component Testing
Use this guide to test each UI component against its specific API endpoints.

### Step 3: End-to-End Workflow Testing
Verify complete user journeys work with real data.

## 📱 Component → API Endpoint Mapping

### 1. Vacancy Planning Module (Feature 27)
**UI Component**: `VacancyPlanningModule.tsx`
**Route**: `/vacancy-planning/*`

**Required API Endpoints**:
```
GET    /api/v1/vacancy-planning/settings                    # Configuration
PUT    /api/v1/vacancy-planning/settings                    # Update config
POST   /api/v1/vacancy-planning/analysis                    # Start analysis
GET    /api/v1/vacancy-planning/analysis/{id}/status        # Progress
GET    /api/v1/vacancy-planning/analysis/{id}/results       # Results
GET    /api/v1/vacancy-planning/tasks                       # Task list
POST   /api/v1/vacancy-planning/tasks/{id}/cancel          # Cancel task
POST   /api/v1/vacancy-planning/exchange/push              # Exchange integration
POST   /api/v1/vacancy-planning/personnel/sync             # Personnel sync
POST   /api/v1/vacancy-planning/reports/generate           # Generate report
GET    /api/v1/vacancy-planning/reports/history            # Report history
```

**Test Commands**:
```bash
curl -X GET http://localhost:8000/api/v1/vacancy-planning/settings
curl -X POST http://localhost:8000/api/v1/vacancy-planning/analysis \
  -H "Content-Type: application/json" \
  -d '{"period": {"start": "2024-01-01", "end": "2024-01-31"}}'
```

### 2. Personnel Management (Feature 16)
**UI Components**: 
- `SystemUserManagement.tsx`
- `EnhancedEmployeeProfilesUI.tsx`
**Routes**: `/admin/users`, `/employees/enhanced-profiles`

**Required API Endpoints**:
```
GET    /api/v1/personnel/employees                          # List employees
POST   /api/v1/personnel/employees                          # Create employee
GET    /api/v1/personnel/employees/{id}                     # Get employee
PUT    /api/v1/personnel/employees/{id}                     # Update employee
DELETE /api/v1/personnel/employees/{id}                     # Delete employee
POST   /api/v1/personnel/employees/{id}/skills              # Assign skills
GET    /api/v1/personnel/employees/{id}/skills              # Get skills
PUT    /api/v1/personnel/employees/{id}/work-settings       # Work settings
GET    /api/v1/personnel/employees/{id}/work-settings       # Get settings
GET    /api/v1/personnel/departments                        # List departments
GET    /api/v1/personnel/skills                             # Available skills
GET    /api/v1/personnel/groups                             # Employee groups
```

**Test Commands**:
```bash
curl -X GET http://localhost:8000/api/v1/personnel/employees
curl -X POST http://localhost:8000/api/v1/personnel/employees \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Employee", "email": "test@company.com"}'
```

### 3. Real-time Monitoring (Feature 15)
**UI Components**:
- `OperationalControlDashboard.tsx`
- `MobileMonitoringDashboard.tsx`
**Routes**: `/monitoring/operational`, `/monitoring/mobile`

**Required API Endpoints**:
```
GET    /api/v1/monitoring/operational                       # Main metrics
GET    /api/v1/monitoring/agents                           # Agent status
GET    /api/v1/monitoring/queues                           # Queue metrics
GET    /api/v1/monitoring/alerts                           # Active alerts
POST   /api/v1/monitoring/alerts/{id}/acknowledge          # Acknowledge alert
WS     ws://localhost:8000/ws/monitoring                   # Real-time updates
```

**WebSocket Events**:
```javascript
// Subscribe to real-time updates
ws.send(JSON.stringify({
  type: 'subscribe',
  channel: 'monitoring',
  events: ['agent_status', 'queue_metrics', 'sla_alert']
}));
```

### 4. Schedule Management (Features 24, 09)
**UI Components**:
- `ScheduleOptimizationUI.tsx`
- `ScheduleGridContainer.tsx`
**Routes**: `/scheduling/optimization`, `/schedule`

**Required API Endpoints**:
```
GET    /api/v1/schedules/current                           # Current schedule
GET    /api/v1/schedules/{date-range}                      # Schedule range
POST   /api/v1/schedules/generate                          # Generate schedule
PUT    /api/v1/schedules/shifts/{id}                       # Update shift
POST   /api/v1/schedules/validate                          # Validate schedule
POST   /api/v1/schedules/mass-assign                       # Mass assignment
POST   /api/v1/schedules/{id}/optimize                     # Optimize schedule
POST   /api/v1/schedules/{id}/publish                      # Publish schedule
WS     ws://localhost:8000/ws/schedules                    # Schedule updates
```

### 5. Mobile Personal Cabinet (Feature 14)
**UI Component**: `MobilePersonalCabinet.tsx`
**Route**: `/mobile/*`

**Required API Endpoints**:
```
GET    /api/v1/mobile/dashboard                            # Dashboard data
GET    /api/v1/mobile/notifications                        # Notifications
POST   /api/v1/mobile/notifications/{id}/read             # Mark read
PUT    /api/v1/mobile/profile                             # Update profile
GET    /api/v1/mobile/calendar?month={month}              # Calendar data
POST   /api/v1/mobile/requests                            # Submit request
GET    /api/v1/mobile/requests                            # My requests
```

### 6. Forecasting & Analytics (Features 08, 12)
**UI Components**:
- `LoadPlanningUI.tsx`
- `ReportBuilderUI.tsx`
- `ForecastingAnalytics.tsx`
**Routes**: `/forecasting/load-planning`, `/reports/builder`

**Required API Endpoints**:
```
GET    /api/v1/forecasting/forecasts?period={period}       # Get forecasts
POST   /api/v1/forecasting/forecasts                       # Create forecast
GET    /api/v1/forecasting/accuracy                        # Accuracy metrics
POST   /api/v1/forecasting/import                          # Import data
GET    /api/v1/reports/templates                           # Report templates
POST   /api/v1/reports/generate                            # Generate report
GET    /api/v1/reports/history                             # Report history
GET    /api/v1/reports/{id}/export?format={format}        # Export report
```

### 7. System Administration (Feature 18)
**UI Components**:
- `DatabaseAdminDashboard.tsx`
- `ServiceManagementConsole.tsx`
**Routes**: `/admin/database`, `/admin/services`

**Required API Endpoints**:
```
GET    /api/v1/admin/users                                 # List users
POST   /api/v1/admin/users                                 # Create user
PUT    /api/v1/admin/users/{id}                            # Update user
GET    /api/v1/admin/database/health                       # DB health
GET    /api/v1/admin/system/metrics                        # System metrics
GET    /api/v1/admin/services                              # Service list
POST   /api/v1/admin/services/{id}/restart                # Restart service
```

### 8. Integration & External Systems (Feature 21)
**UI Component**: `IntegrationDashboardUI.tsx`
**Route**: `/integrations/dashboard`

**Required API Endpoints**:
```
GET    /api/v1/integrations/status                         # Integration status
POST   /api/v1/integrations/{type}/test                    # Test integration
POST   /api/v1/integrations/{type}/sync                    # Sync data
GET    /api/v1/integrations/1c-zup/status                 # 1C ZUP status
POST   /api/v1/integrations/1c-zup/sync                   # 1C ZUP sync
GET    /api/v1/integrations/sap-hr/status                 # SAP HR status
```

### 9. Time & Attendance (Feature 29)
**UI Component**: `TimeAttendanceUI.tsx`
**Route**: `/time-attendance/dashboard`

**Required API Endpoints**:
```
POST   /api/v1/time-attendance/clock-in                    # Clock in
POST   /api/v1/time-attendance/clock-out                   # Clock out
GET    /api/v1/time-attendance/calendar                    # Attendance calendar
GET    /api/v1/time-attendance/exceptions                  # Exception list
POST   /api/v1/time-attendance/overtime/approve           # Approve overtime
GET    /api/v1/time-attendance/payroll-integration        # Payroll data
```

### 10. Reference Data Management (Feature 17)
**UI Component**: `ReferenceDataConfigurationUI.tsx`
**Route**: `/reference-data/config`

**Required API Endpoints**:
```
GET    /api/v1/reference-data/work-rules                   # Work rules
PUT    /api/v1/reference-data/work-rules                   # Update rules
GET    /api/v1/reference-data/events                       # Event types
POST   /api/v1/reference-data/events                       # Create event
GET    /api/v1/reference-data/vacation-schemes             # Vacation schemes
GET    /api/v1/reference-data/absence-reasons              # Absence reasons
```

## 🔧 Core System APIs

### Authentication & Security
**Used by**: All components
```
POST   /api/v1/auth/login                                  # User login
POST   /api/v1/auth/logout                                 # User logout
POST   /api/v1/auth/refresh                                # Refresh token
GET    /api/v1/auth/profile                                # User profile
```

### Health & Status
**Used by**: Integration testing, system monitoring
```
GET    /api/v1/health                                      # API health
GET    /api/v1/integration/database/health                 # Database status
GET    /api/v1/integration/algorithms/test-integration    # Algorithm status
GET    /api/v1/integration/status                          # Overall status
```

### Real-time WebSocket Channels
**Base URL**: `ws://localhost:8000/ws`

**Channels**:
```
/ws/monitoring          # Real-time metrics and alerts
/ws/schedules           # Schedule changes and updates
/ws/vacancy             # Vacancy analysis progress
/ws/notifications       # User notifications
/ws/tasks               # Background task updates
```

## ⚡ Quick Integration Testing

### 1. Basic Connectivity Test
```bash
# Test if API is running
curl http://localhost:8000/api/v1/health

# Should return: {"status": "healthy", "timestamp": "..."}
```

### 2. Database Integration Test
```bash
# Test database connection
curl http://localhost:8000/api/v1/integration/database/health

# Should return: {"database": "connected", "tables": 42, "status": "healthy"}
```

### 3. Personnel Management Test
```bash
# Test employee list
curl http://localhost:8000/api/v1/personnel/employees

# Should return: {"employees": [...], "total": N}
```

### 4. Vacancy Planning Test
```bash
# Test vacancy settings
curl http://localhost:8000/api/v1/vacancy-planning/settings

# Should return: {"minimumVacancyEfficiency": 85, "analysisPeriod": 30, ...}
```

### 5. WebSocket Test
```javascript
// Test WebSocket connection
const ws = new WebSocket('ws://localhost:8000/ws');
ws.onopen = () => console.log('WebSocket connected');
ws.onerror = (error) => console.error('WebSocket error:', error);
```

## 🐛 Common Integration Issues & Solutions

### Issue 1: CORS Errors
**Symptoms**: Browser console shows CORS policy errors
**Solution**: Add CORS headers to API:
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Issue 2: 404 Not Found
**Symptoms**: Endpoints return 404 status
**Solution**: Check if endpoints exist in API router:
```python
# Verify endpoint is registered
@router.get("/api/v1/personnel/employees")
async def get_employees():
    return {"employees": []}
```

### Issue 3: WebSocket Connection Failed
**Symptoms**: Real-time updates not working
**Solution**: UI automatically falls back to polling. Check WebSocket endpoint:
```python
# Ensure WebSocket endpoint exists
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
```

### Issue 4: Authentication Errors
**Symptoms**: 401 Unauthorized responses
**Solution**: UI includes bearer token in requests:
```javascript
// Token is automatically included
headers: {
  'Authorization': `Bearer ${localStorage.getItem('authToken')}`
}
```

### Issue 5: Slow Response Times
**Symptoms**: UI shows loading states for too long
**Solution**: Optimize API endpoints or UI will use cached data:
```python
# Add response time logging
import time
start_time = time.time()
# ... process request ...
print(f"Request took {time.time() - start_time:.2f}s")
```

## 📊 Integration Testing Checklist

### Phase 1: Basic Connectivity ✅
- [ ] Health check returns 200
- [ ] Database health returns status
- [ ] CORS headers configured
- [ ] Basic authentication working

### Phase 2: Core Features ✅
- [ ] Employee list loads
- [ ] Employee creation works
- [ ] Vacancy settings load
- [ ] Basic reporting works

### Phase 3: Real-time Features ✅
- [ ] WebSocket connects
- [ ] Real-time metrics update
- [ ] Notifications work
- [ ] Schedule updates propagate

### Phase 4: Advanced Features ✅
- [ ] File upload works
- [ ] PDF generation works
- [ ] External integrations work
- [ ] Performance <100ms

## 🎯 Success Metrics

### Demo Ready
- ✅ 16+ critical endpoints working
- ✅ Basic UI navigation functional
- ✅ Real data displays in components
- ✅ No blocking errors

### Production Ready
- ✅ All 517 endpoints functional
- ✅ <100ms average response time
- ✅ WebSocket real-time updates
- ✅ File operations working
- ✅ Comprehensive error handling

## 📞 Support for INTEGRATION-OPUS

### UI-Provided Tools:
1. **Integration Tester** - Automated endpoint testing
2. **API Documentation** - Complete endpoint specifications
3. **Error Logging** - Detailed request/response logging
4. **Mock Data** - Examples of expected data formats
5. **Performance Monitoring** - Response time tracking

### Next Steps:
1. Start INTEGRATION-OPUS API on port 8000
2. Navigate to `/integration-tester` in UI
3. Run systematic tests and fix issues
4. Use this guide for component-specific testing
5. Achieve 100% integration success!

---

**Ready for seamless UI ↔ API integration!** 🚀