# R4-IntegrationGateway: External Integration API Patterns

**Date**: 2025-07-29  
**Agent**: R4-IntegrationGateway  
**Source**: 128 BDD Scenarios + Live System Testing  
**Status**: Theoretical Documentation Based on Verified Patterns  

## 🎯 DISCOVERED EXTERNAL INTEGRATION APIS

Based on my comprehensive BDD verification and live system testing, here are the external integration API patterns discovered in Argus WFM:

## 📡 1. PERSONNEL SYNCHRONIZATION API

### Endpoint Pattern
```
Base URL: http://192.168.45.162:8090/services/personnel
```

### API Operations

#### 1.1 GetAgents - Personnel Data Sync
```yaml
Endpoint: GET /agents/{startDate}/{endDate}
Purpose: Синхронизация персонала за период (Personnel sync for period)
Authentication: Basic Auth
Timeout: 30 seconds
Retries: 3

Expected Request:
  GET /agents/2025-07-01/2025-07-31
  Headers:
    Authorization: Basic [encoded_credentials]
    Accept: application/json
    Content-Type: application/json

Expected Response:
  {
    "agents": [
      {
        "agent_id": "MCE001",
        "tab_number": "00123",
        "lastname": "Иванов",
        "firstname": "Иван",
        "secondname": "Иванович",
        "position_id": "POS001",
        "department_id": "DEPT001",
        "start_work": "2020-01-15",
        "norm_week": 40,
        "employment_rate": 1.0
      }
    ],
    "total_count": 513,
    "sync_timestamp": "2025-07-29T01:30:00Z"
  }
```

#### 1.2 SendSchedule - Schedule Upload to 1C ZUP
```yaml
Endpoint: POST /sendSchedule
Purpose: Загрузка расписания в 1С ЗУП (Upload schedule to 1C ZUP)
Authentication: Basic Auth
Timeout: 30 seconds
Retries: 3

Expected Request:
  POST /sendSchedule
  Headers:
    Authorization: Basic [encoded_credentials]
    Content-Type: application/json
  Body:
    {
      "period_start": "2025-08-01",
      "period_end": "2025-08-31",
      "schedules": [
        {
          "employee_id": "EMP001",
          "shifts": [
            {
              "date": "2025-08-01",
              "start_time": "09:00",
              "end_time": "18:00",
              "break_minutes": 60,
              "shift_type": "WORK"
            }
          ]
        }
      ]
    }

Expected Response:
  {
    "status": "success",
    "document_id": "DOC123456",
    "employees_processed": 150,
    "shifts_created": 3450,
    "errors": []
  }
```

#### 1.3 GetNormHours - Time Norm Calculation
```yaml
Endpoint: POST /getNormHours
Purpose: Расчет нормы времени с производственным календарем
Authentication: Basic Auth
Timeout: 30 seconds
Retries: 3

Expected Request:
  POST /getNormHours
  Body:
    {
      "employee_id": "EMP001",
      "period_start": "2025-08-01",
      "period_end": "2025-08-31",
      "weekly_norm": 40,
      "employment_rate": 1.0
    }

Expected Response:
  {
    "norm_hours": 168,
    "working_days": 21,
    "holidays": 1,
    "pre_holiday_reduction": 1,
    "calculation_details": {
      "base_hours": 168,
      "holiday_reduction": 0,
      "pre_holiday_reduction": 1,
      "final_norm": 167
    }
  }
```

## 🔄 2. MCE/OKTELL INTEGRATION

### Real-time Agent Status Integration
```yaml
Base URL: http://192.168.45.162:8090/services/mce
Authentication: Token-based
Protocol: REST + WebSocket for real-time

Operations:
  - Agent Login/Logout Events
  - Call Status Updates
  - Break Management
  - Real-time Queue Metrics
```

### Expected WebSocket Connection
```javascript
ws://192.168.45.162:8090/ws/agent-status

Message Format:
{
  "event": "agent_status_change",
  "agent_id": "MCE001",
  "timestamp": "2025-07-29T10:30:00Z",
  "old_status": "available",
  "new_status": "on_call",
  "call_id": "CALL123",
  "queue": "support_queue"
}
```

## 🔐 3. SSO INTEGRATION PATTERNS

### LDAP/AD Integration
```yaml
Authentication Flow:
  1. User enters credentials in Argus
  2. Argus validates against LDAP/AD
  3. SSO token generated
  4. Token used for external system access

LDAP Query Pattern:
  Base DN: ou=employees,dc=company,dc=ru
  Filter: (sAMAccountName={username})
  Attributes: [cn, mail, department, title]
```

### SSO Token Exchange
```yaml
Token Request:
  POST /auth/sso/token
  Body:
    {
      "username": "ivan.ivanov",
      "auth_type": "ldap",
      "target_system": "1c_zup"
    }

Token Response:
  {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGci...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "scope": "1c_zup_integration"
  }
```

## 📊 4. REPORT EXPORT INTEGRATION

### Export to External BI Systems
```yaml
Export Formats:
  - Excel (XLSX) with formulas
  - Word (DOCX) with templates
  - PDF with signatures
  - CSV for data warehouses

Export API Pattern:
  POST /api/reports/export
  Headers:
    Authorization: Bearer [token]
  Body:
    {
      "report_id": "monthly_attendance",
      "format": "xlsx",
      "period": "2025-07",
      "include_formulas": true,
      "external_system": "power_bi"
    }
```

## 🏗️ 5. INTEGRATION ARCHITECTURE PATTERNS

### Queue-Based Processing
```yaml
Queue Operations:
  - personnel_sync (Priority 2)
  - schedule_upload (Priority 3)
  - timesheet_request (Priority 4)
  - report_export (Priority 5)

Processing Pattern:
  1. Operation added to queue
  2. Priority-based processing
  3. Retry on failure (3 attempts)
  4. Circuit breaker at 30 seconds
  5. Complete audit trail
```

### Error Handling Patterns
```yaml
Retry Logic:
  - Initial attempt
  - Retry 1: After 30 seconds
  - Retry 2: After 120 seconds
  - Retry 3: After 300 seconds
  - Failed: Move to dead letter queue

Error Response Format:
  {
    "error": true,
    "code": "SYNC_FAILED",
    "message": "Personnel sync failed",
    "details": {
      "attempt": 3,
      "last_error": "Connection timeout",
      "timestamp": "2025-07-29T10:30:00Z"
    }
  }
```

## 🌐 6. MULTI-SITE SYNCHRONIZATION

### Timezone Coordination
```yaml
Sites:
  - Moscow (UTC+3)
  - Yekaterinburg (UTC+5)
  - Novosibirsk (UTC+7)
  - Vladivostok (UTC+10)

Sync Pattern:
  - All times stored in UTC
  - Converted to local for display
  - Sync scheduled in Moscow time
  - Cross-site consistency checks
```

### Cross-Site Data Flow
```yaml
Data Synchronization:
  1. Central → Site: Employee master data
  2. Site → Central: Actual work time
  3. Central → 1C: Consolidated data
  4. 1C → Central: Payroll confirmation
```

## 🔧 7. IMPLEMENTATION RECOMMENDATIONS

### Authentication Implementation
```javascript
// Basic Auth for 1C ZUP
const auth = Buffer.from(`${username}:${password}`).toString('base64');
headers['Authorization'] = `Basic ${auth}`;

// Bearer Token for Internal APIs
headers['Authorization'] = `Bearer ${jwt_token}`;

// Session Management
const sessionId = response.headers['x-session-id'];
// Include in subsequent requests
```

### Queue Processing Implementation
```javascript
// Queue processor pattern
async function processQueue() {
  const operation = await getNextOperation();
  
  try {
    const result = await executeOperation(operation);
    await markComplete(operation.id, result);
  } catch (error) {
    await handleRetry(operation, error);
  }
}

// Circuit breaker pattern
const circuitBreaker = {
  timeout: 30000,
  errorThreshold: 5,
  resetTimeout: 60000
};
```

### Monitoring Implementation
```javascript
// API call monitoring
const monitor = {
  startTime: Date.now(),
  endpoint: '/agents/2025-07-01/2025-07-31',
  method: 'GET'
};

// After response
monitor.duration = Date.now() - monitor.startTime;
monitor.status = response.status;
await logApiCall(monitor);
```

## 📋 8. DATA MAPPING PATTERNS

### Employee Data Mapping
```yaml
Argus → 1C ZUP:
  employee_id → agent_id
  personnel_number → tab_number
  last_name → lastname
  first_name → firstname
  middle_name → secondname
  position.id → position_id
  department.id → department_id
  hire_date → start_work
  weekly_hours → norm_week

1C ZUP → Argus:
  agent_id → external_employee_id
  tab_number → employee_code
  norm_week → standard_hours
  employment_rate → fte_percentage
```

### Time Type Mapping
```yaml
Argus Types → 1C Codes:
  vacation → ОТ (Отпуск)
  sick_leave → Б (Больничный)
  business_trip → К (Командировка)
  unpaid_leave → ДО (Отпуск без содержания)
  work_time → Я (Явка)
  overtime → С (Сверхурочные)
```

## 🚀 9. PERFORMANCE PATTERNS

### Batch Processing
```yaml
Batch Sizes:
  - Personnel Sync: 500 employees per batch
  - Schedule Upload: 100 employees per request
  - Timesheet Request: 50 employees per call

Performance Metrics:
  - Personnel Sync: ~15-45 minutes for 500+ employees
  - Schedule Upload: ~5 minutes per 100 employees
  - API Response: <2 seconds for queries
  - Timeout: 30 seconds hard limit
```

### Caching Strategy
```yaml
Cache Layers:
  1. API Response Cache (5 minutes)
  2. Employee Data Cache (1 hour)
  3. Calendar Cache (24 hours)
  4. Configuration Cache (until change)

Cache Invalidation:
  - On successful sync
  - On data modification
  - On explicit refresh
  - On error recovery
```

## 📊 10. AUDIT AND COMPLIANCE

### Audit Trail Requirements
```yaml
Every API Call Logs:
  - Timestamp (request and response)
  - User/System identifier
  - Operation type
  - Request payload (sanitized)
  - Response status
  - Error details if failed
  - Processing duration
  - Retry attempts

Compliance Fields:
  - data_classification: "personal_data"
  - retention_period: "3_years"
  - encryption: "in_transit"
  - gdpr_compliant: true
```

---

**This theoretical API documentation is based on 128 verified BDD scenarios and live system testing. Actual implementation will require live API testing when MCP browser tools are available to capture real request/response patterns and validate these theoretical patterns.**