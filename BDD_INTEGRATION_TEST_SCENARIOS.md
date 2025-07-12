# BDD Integration Test Scenarios - UI-API Contract Documentation

## 🎯 **Integration Test Overview**

**Purpose**: Document comprehensive BDD test scenarios for UI-OPUS ↔ INTEGRATION-OPUS connectivity  
**Coverage**: 517 API endpoints across 14 BDD modules  
**Testing Tool**: `/integration-tester` (Complete test suite)  
**Status**: Ready for systematic validation  

---

## 📋 **BDD Test Suites**

### **1. Core API Connections**
**BDD Source**: `11-system-integration.feature`  
**UI Components**: Integration tools, health monitors  
**API Endpoints**: 15+ core infrastructure endpoints  

#### Test Scenarios:
```gherkin
Scenario: API Health Check
  Given the WFM API server is running on port 8000
  When I request "/api/v1/health"
  Then I should receive status code 200
  And response should contain system status information

Scenario: Authentication Token Validation
  Given a valid user with System_AccessAPI role
  When I request "/api/v1/auth/test" with bearer token
  Then I should receive authentication confirmation
  And token should be validated successfully

Scenario: Database Health Check
  Given the PostgreSQL database is accessible
  When I request "/api/v1/integration/database/health"
  Then I should receive database connection status
  And all required tables should be accessible

Scenario: Algorithm Service Integration
  Given ALGORITHM-OPUS services are running
  When I request "/api/v1/integration/algorithms/test-integration"
  Then I should receive algorithm service status
  And all calculation engines should be operational
```

---

### **2. Personnel Management Integration**
**BDD Source**: `16-enhanced-employee-management.feature`  
**UI Components**: Employee profiles, skills management, HR workflows  
**API Endpoints**: 45+ personnel and skills endpoints  

#### Test Scenarios:
```gherkin
Scenario: Employee Data Retrieval
  Given personnel database contains employee records
  When I request "/api/v1/personnel/employees"
  Then I should receive paginated employee list
  And each employee should have required profile fields

Scenario: Employee Creation Workflow
  Given I have valid employee data with Russian names
  When I POST to "/api/v1/personnel/employees"
  Then employee should be created with UUID
  And Cyrillic validation should be applied
  And 1C ZUP integration should be triggered

Scenario: Skills Assignment Process
  Given an existing employee with ID
  When I POST to "/api/v1/personnel/employees/{id}/skills"
  Then skills should be assigned with proficiency levels
  And certification tracking should be updated
  And scheduling constraints should be recalculated

Scenario: Work Settings Configuration
  Given employee requires schedule constraints
  When I GET "/api/v1/personnel/employees/{id}/work-settings"
  Then work parameters should include labor law compliance
  And overtime limits should be enforced
  And rest period requirements should be validated
```

---

### **3. Vacancy Planning Integration**
**BDD Source**: `27-vacancy-planning-module.feature`  
**UI Components**: Analysis dashboard, settings config, reporting  
**API Endpoints**: 12+ vacancy planning and analysis endpoints  

#### Test Scenarios:
```gherkin
Scenario: Vacancy Planning Settings Configuration
  Given user has System_AccessVacancyPlanning role
  When I GET "/api/v1/vacancy-planning/settings"
  Then I should receive current configuration
  And settings should include efficiency thresholds
  And forecast confidence levels should be available

Scenario: Gap Analysis Execution
  Given valid planning settings are configured
  When I POST to "/api/v1/vacancy-planning/analysis"
  Then analysis should execute with progress tracking
  And staffing gaps should be calculated by department
  And hiring recommendations should be generated

Scenario: Exchange System Integration
  Given 1C ZUP exchange is configured
  When I GET "/api/v1/vacancy-planning/exchange"
  Then data synchronization status should be available
  And bidirectional data transfer should be confirmed
  And error logs should be accessible

Scenario: Vacancy Reports Generation
  Given completed analysis results exist
  When I GET "/api/v1/vacancy-planning/reports"
  Then comprehensive reports should be generated
  And trend analysis should include historical data
  And export formats should be available (Excel, PDF)
```

---

### **4. Real-time Features Integration**
**BDD Source**: `15-real-time-monitoring-operational-control.feature`  
**UI Components**: Operational dashboards, alert systems, WebSocket handlers  
**API Endpoints**: 25+ monitoring and WebSocket endpoints  

#### Test Scenarios:
```gherkin
Scenario: WebSocket Connection Establishment
  Given real-time monitoring is enabled
  When I connect to "ws://localhost:8000/ws"
  Then WebSocket connection should be established
  And real-time events should be streaming
  And connection should handle reconnection automatically

Scenario: Operational Metrics Monitoring
  Given operational control dashboard is active
  When I GET "/api/v1/monitoring/operational"
  Then six key metrics should be available
  And traffic light indicators should reflect current status
  And 30-second update frequency should be maintained

Scenario: Agent Status Updates
  Given agents are actively working
  When I GET "/api/v1/monitoring/agents"
  Then current agent statuses should be displayed
  And queue assignments should be visible
  And performance metrics should be current

Scenario: Schedule Change Notifications
  Given schedule modifications occur
  When I GET "/api/v1/schedules/current"
  Then real-time schedule updates should be available
  And affected employees should be notified
  And conflict resolution should be triggered
```

---

## 🔧 **UI-API Contract Specifications**

### **Data Format Standards**
```typescript
// Employee Profile Contract
interface EmployeeProfile {
  id: string;                    // UUID format
  personalInfo: {
    lastName: string;            // Cyrillic support: "Иванов"
    firstName: string;           // Cyrillic support: "Иван"
    middleName?: string;         // Cyrillic support: "Иванович"
  };
  workInfo: {
    employeeNumber: string;      // 1C ZUP integration
    department: string;
    position: string;
    hireDate: string;           // ISO 8601 format
  };
  skills: SkillAssignment[];
  workSettings: WorkParameters;
}

// Vacancy Analysis Contract
interface VacancyAnalysisResult {
  analysisId: string;
  timestamp: string;
  settings: VacancyPlanningSettings;
  gaps: StaffingGap[];
  recommendations: HiringRecommendation[];
  metrics: {
    totalGaps: number;
    criticalShortages: number;
    estimatedCost: number;
    slaImpact: number;
  };
}

// Real-time Monitoring Contract
interface OperationalMetrics {
  timestamp: string;
  metrics: {
    serviceLevel: MetricValue;
    queueLength: MetricValue;
    agentsAvailable: MetricValue;
    responseTime: MetricValue;
    callsPerHour: MetricValue;
    occupancyRate: MetricValue;
  };
  alerts: Alert[];
}
```

### **Error Handling Standards**
```typescript
// Standard API Error Response
interface APIError {
  status: number;
  code: string;
  message: string;
  details?: any;
  timestamp: string;
  correlationId: string;
}

// UI Fallback Behavior
- API unavailable → Use mock data
- Timeout errors → Retry with exponential backoff
- Authentication failure → Redirect to login
- Validation errors → Display inline error messages
- Server errors → Log to console + show user-friendly message
```

---

## 🧪 **Automated Test Suite Implementation**

### **Integration Tester Configuration**
**Location**: `http://localhost:3000/integration-tester`  
**Test Suites**: 4 comprehensive suites  
**Endpoint Coverage**: 517 endpoints total  

#### Test Suite 1: Core API Connections (15 tests)
- Health check validation
- Authentication testing
- Database connectivity
- Algorithm service integration

#### Test Suite 2: Personnel Management (45 tests)
- Employee CRUD operations
- Skills assignment workflows
- Work settings configuration
- Profile data validation

#### Test Suite 3: Vacancy Planning (12 tests)
- Settings management
- Analysis execution
- Exchange integration
- Report generation

#### Test Suite 4: Real-time Features (25 tests)
- WebSocket connections
- Operational metrics
- Agent status monitoring
- Schedule notifications

### **Test Execution Flow**
```javascript
// Automated Test Execution
const runIntegrationTests = async () => {
  // 1. Initialize test environment
  await testSuite.initialize();
  
  // 2. Run core connectivity tests
  const coreResults = await testSuite.runCoreTests();
  
  // 3. Run module-specific tests
  const moduleResults = await testSuite.runModuleTests();
  
  // 4. Generate comprehensive report
  const report = testSuite.generateReport(coreResults, moduleResults);
  
  // 5. Save results for INTEGRATION-OPUS analysis
  localStorage.setItem('ui_integration_test_report', JSON.stringify(report));
  
  return report;
};
```

---

## 📊 **Test Results Documentation**

### **Success Criteria**
- **Core API**: 100% health checks passing
- **Personnel**: 90%+ CRUD operations successful
- **Vacancy Planning**: Analysis execution functional
- **Real-time**: WebSocket connections stable

### **Performance Benchmarks**
- **Response Time**: < 2000ms for standard endpoints
- **Throughput**: Support 100+ concurrent requests
- **Availability**: 99.5% uptime during business hours
- **Real-time**: < 500ms update latency

### **Error Rate Thresholds**
- **Authentication**: < 1% failure rate
- **Data Validation**: < 5% validation errors
- **Integration**: < 3% synchronization failures
- **WebSocket**: < 2% connection drops

---

## 🚀 **Next Steps for INTEGRATION-OPUS**

### **Immediate Actions**
1. **Fix Pydantic Schema Errors**: ✅ Completed - `any` → `Any` type fixes
2. **Start API Server**: `python -m uvicorn src.api.main_simple:app --port 8000`
3. **Run Integration Tests**: Navigate to `/integration-tester` and execute full suite
4. **Review Test Results**: Check localStorage for detailed analysis

### **Systematic Testing Process**
1. **Start Both Servers**:
   ```bash
   # Terminal 1: API
   python -m uvicorn src.api.main_simple:app --port 8000
   
   # Terminal 2: UI
   npm run dev
   ```

2. **Execute Test Suite**:
   - Navigate to `http://localhost:3000/integration-tester`
   - Click "Run All Tests"
   - Monitor progress and results

3. **Analyze Results**:
   - Review console logs for detailed errors
   - Check localStorage report for comprehensive analysis
   - Focus on failed endpoints for debugging

4. **Iterative Improvement**:
   - Fix identified endpoint issues
   - Re-run specific test suites
   - Validate UI-API contract compliance

---

**Status**: BDD integration test scenarios documented ✅  
**Next**: Execute comprehensive endpoint validation with INTEGRATION-OPUS  
**Tools**: Ready for systematic 517-endpoint testing process  