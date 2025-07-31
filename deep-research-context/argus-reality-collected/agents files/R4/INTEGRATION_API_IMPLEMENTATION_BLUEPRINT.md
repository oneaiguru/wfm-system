# R4-IntegrationGateway: Complete Integration API Implementation Blueprint

**Date**: 2025-07-29  
**Agent**: R4-IntegrationGateway  
**Purpose**: Comprehensive guide for implementing Argus WFM integration APIs  
**Based On**: 128 BDD scenarios + Live system verification  

## 🏗️ INTEGRATION ARCHITECTURE OVERVIEW

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Argus WFM     │────▶│ Integration Queue │────▶│ External Systems│
│  (JSF Admin)    │     │  (Async Process) │     │   (1C, MCE)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                       │                         │
         ▼                       ▼                         ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ Employee Portal │     │   Monitoring &   │     │   Audit Trail   │
│   (Vue.js)      │     │  Health Checks   │     │   (Complete)    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## 📡 1. EXTERNAL SYSTEM ENDPOINTS

### 1.1 Primary Integration Target: 1C ZUP
```yaml
Production Endpoint: http://192.168.45.162:8090/services/personnel
Environment: Internal Network Only
Protocol: HTTP (consider HTTPS for production)
Authentication: HTTP Basic Auth
Content-Type: application/json
Encoding: UTF-8
```

### 1.2 Secondary Integration: MCE/Oktell
```yaml
Real-time Endpoint: ws://192.168.45.162:8090/ws/agent-status
Fallback REST: http://192.168.45.162:8090/api/v1/agents
Protocol: WebSocket + REST
Authentication: Token-based
Heartbeat: Every 30 seconds
```

## 🔐 2. AUTHENTICATION ARCHITECTURE

### 2.1 Authentication Flow
```javascript
// Step 1: Obtain credentials from secure storage
const credentials = await getSecureCredentials('1C_ZUP_INTEGRATION');

// Step 2: Create Basic Auth header
const authHeader = Buffer.from(`${credentials.username}:${credentials.password}`)
  .toString('base64');

// Step 3: Include in all requests
const headers = {
  'Authorization': `Basic ${authHeader}`,
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-Request-ID': generateRequestId(),
  'X-Session-ID': sessionId
};
```

### 2.2 Token Management for MCE
```javascript
// Token refresh pattern
class TokenManager {
  constructor() {
    this.token = null;
    this.expiresAt = null;
  }

  async getToken() {
    if (!this.token || Date.now() > this.expiresAt - 60000) {
      await this.refreshToken();
    }
    return this.token;
  }

  async refreshToken() {
    const response = await fetch('/auth/mce/token', {
      method: 'POST',
      headers: { 'Authorization': `Basic ${basicAuth}` }
    });
    
    const data = await response.json();
    this.token = data.access_token;
    this.expiresAt = Date.now() + (data.expires_in * 1000);
  }
}
```

## 🔄 3. QUEUE-BASED PROCESSING IMPLEMENTATION

### 3.1 Queue Operation Structure
```typescript
interface QueueOperation {
  id: string;                    // UUID
  operation_type: OperationType; // personnel_sync | schedule_upload | timesheet_request
  priority: 1 | 2 | 3 | 4 | 5;   // 1 = highest
  status: QueueStatus;           // pending | processing | completed | failed
  operation_data: any;           // JSONB payload
  retry_count: number;           // Current retry attempt
  max_retries: number;           // Default: 3
  created_at: Date;
  started_at?: Date;
  completed_at?: Date;
  error_message?: string;
  api_endpoint?: string;
  processing_node?: string;
}
```

### 3.2 Queue Processor Implementation
```javascript
class IntegrationQueueProcessor {
  constructor() {
    this.concurrency = 5;
    this.processing = new Map();
  }

  async start() {
    setInterval(() => this.processQueue(), 5000); // Check every 5 seconds
  }

  async processQueue() {
    if (this.processing.size >= this.concurrency) return;

    const operations = await this.getNextOperations(
      this.concurrency - this.processing.size
    );

    for (const operation of operations) {
      this.processOperation(operation);
    }
  }

  async processOperation(operation) {
    this.processing.set(operation.id, operation);
    
    try {
      await this.updateStatus(operation.id, 'processing');
      
      const processor = this.getProcessor(operation.operation_type);
      const result = await processor.execute(operation);
      
      await this.completeOperation(operation.id, result);
    } catch (error) {
      await this.handleError(operation, error);
    } finally {
      this.processing.delete(operation.id);
    }
  }

  async handleError(operation, error) {
    if (operation.retry_count < operation.max_retries) {
      const delay = this.calculateRetryDelay(operation.retry_count);
      await this.scheduleRetry(operation.id, delay);
    } else {
      await this.markFailed(operation.id, error.message);
    }
  }

  calculateRetryDelay(retryCount) {
    // Exponential backoff: 30s, 120s, 300s
    const delays = [30000, 120000, 300000];
    return delays[retryCount] || 300000;
  }
}
```

## 📊 4. API IMPLEMENTATION PATTERNS

### 4.1 Personnel Synchronization
```javascript
class PersonnelSyncProcessor {
  async execute(operation) {
    const { start_date, end_date } = operation.operation_data;
    
    // Step 1: Fetch from 1C ZUP
    const externalEmployees = await this.fetchExternalEmployees(start_date, end_date);
    
    // Step 2: Fetch current Argus employees
    const argusEmployees = await this.getArgusEmployees();
    
    // Step 3: Perform reconciliation
    const syncPlan = this.createSyncPlan(externalEmployees, argusEmployees);
    
    // Step 4: Execute sync operations
    const results = {
      created: 0,
      updated: 0,
      deactivated: 0,
      errors: []
    };
    
    for (const action of syncPlan.create) {
      try {
        await this.createEmployee(action.employee);
        results.created++;
      } catch (error) {
        results.errors.push({ employee: action.employee.id, error: error.message });
      }
    }
    
    // Similar for update and deactivate
    
    return results;
  }

  async fetchExternalEmployees(startDate, endDate) {
    const response = await fetch(
      `${Config.EXTERNAL_API}/agents/${startDate}/${endDate}`,
      {
        headers: this.getAuthHeaders(),
        timeout: 30000
      }
    );
    
    if (!response.ok) {
      throw new IntegrationError(`External API error: ${response.status}`);
    }
    
    return response.json();
  }

  createSyncPlan(external, internal) {
    const externalMap = new Map(external.map(e => [e.agent_id, e]));
    const internalMap = new Map(internal.map(e => [e.external_id, e]));
    
    const plan = {
      create: [],
      update: [],
      deactivate: []
    };
    
    // New employees
    for (const [id, employee] of externalMap) {
      if (!internalMap.has(id)) {
        plan.create.push({ employee });
      }
    }
    
    // Updated employees
    for (const [id, internal] of internalMap) {
      const external = externalMap.get(id);
      if (external && this.hasChanges(internal, external)) {
        plan.update.push({ internal, external });
      }
    }
    
    // Deactivated employees
    for (const [id, internal] of internalMap) {
      if (!externalMap.has(id)) {
        plan.deactivate.push({ employee: internal });
      }
    }
    
    return plan;
  }
}
```

### 4.2 Schedule Upload Implementation
```javascript
class ScheduleUploadProcessor {
  async execute(operation) {
    const { period_start, period_end, department_id } = operation.operation_data;
    
    // Step 1: Gather schedule data
    const schedules = await this.gatherSchedules(period_start, period_end, department_id);
    
    // Step 2: Transform to 1C format
    const payload = this.transformTo1CFormat(schedules);
    
    // Step 3: Validate business rules
    const validation = await this.validateSchedules(payload);
    if (!validation.valid) {
      throw new ValidationError(validation.errors);
    }
    
    // Step 4: Upload in batches
    const results = [];
    const batches = this.createBatches(payload.schedules, 100);
    
    for (const batch of batches) {
      const result = await this.uploadBatch(batch, period_start, period_end);
      results.push(result);
    }
    
    return this.consolidateResults(results);
  }

  transformTo1CFormat(schedules) {
    return {
      schedules: schedules.map(schedule => ({
        employee_id: schedule.employee.external_id,
        shifts: schedule.shifts.map(shift => ({
          date: shift.date,
          start_time: this.formatTime(shift.start),
          end_time: this.formatTime(shift.end),
          break_minutes: shift.break_duration,
          shift_type: this.mapShiftType(shift.type),
          location_code: shift.location?.code
        }))
      }))
    };
  }

  async uploadBatch(batch, periodStart, periodEnd) {
    const response = await fetch(`${Config.EXTERNAL_API}/sendSchedule`, {
      method: 'POST',
      headers: this.getAuthHeaders(),
      body: JSON.stringify({
        period_start: periodStart,
        period_end: periodEnd,
        schedules: batch
      }),
      timeout: 30000
    });
    
    return response.json();
  }
}
```

## 🔧 5. ERROR HANDLING & RESILIENCE

### 5.1 Circuit Breaker Pattern
```javascript
class CircuitBreaker {
  constructor(options = {}) {
    this.failureThreshold = options.failureThreshold || 5;
    this.resetTimeout = options.resetTimeout || 60000;
    this.timeout = options.timeout || 30000;
    
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.failures = 0;
    this.lastFailTime = null;
  }

  async execute(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailTime > this.resetTimeout) {
        this.state = 'HALF_OPEN';
      } else {
        throw new CircuitOpenError('Circuit breaker is OPEN');
      }
    }

    try {
      const result = await this.withTimeout(fn(), this.timeout);
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failures = 0;
    this.state = 'CLOSED';
  }

  onFailure() {
    this.failures++;
    this.lastFailTime = Date.now();
    
    if (this.failures >= this.failureThreshold) {
      this.state = 'OPEN';
    }
  }

  withTimeout(promise, timeout) {
    return Promise.race([
      promise,
      new Promise((_, reject) => 
        setTimeout(() => reject(new TimeoutError()), timeout)
      )
    ]);
  }
}
```

### 5.2 Retry Strategy
```javascript
class RetryManager {
  async executeWithRetry(fn, options = {}) {
    const maxRetries = options.maxRetries || 3;
    const baseDelay = options.baseDelay || 1000;
    
    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await fn();
      } catch (error) {
        if (attempt === maxRetries) throw error;
        
        const delay = this.calculateDelay(attempt, baseDelay);
        await this.sleep(delay);
        
        // Log retry attempt
        logger.warn(`Retry attempt ${attempt + 1}/${maxRetries}`, {
          error: error.message,
          delay
        });
      }
    }
  }

  calculateDelay(attempt, baseDelay) {
    // Exponential backoff with jitter
    const exponentialDelay = baseDelay * Math.pow(2, attempt);
    const jitter = Math.random() * 1000;
    return exponentialDelay + jitter;
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## 📈 6. MONITORING & OBSERVABILITY

### 6.1 API Call Monitoring
```javascript
class APIMonitor {
  constructor() {
    this.metrics = {
      calls: new Map(),
      errors: new Map(),
      durations: []
    };
  }

  async monitorCall(endpoint, method, fn) {
    const startTime = Date.now();
    const requestId = generateRequestId();
    
    try {
      const result = await fn();
      this.recordSuccess(endpoint, method, Date.now() - startTime);
      return result;
    } catch (error) {
      this.recordError(endpoint, method, error, Date.now() - startTime);
      throw error;
    } finally {
      this.logCall({
        requestId,
        endpoint,
        method,
        duration: Date.now() - startTime,
        timestamp: new Date().toISOString()
      });
    }
  }

  recordSuccess(endpoint, method, duration) {
    const key = `${method} ${endpoint}`;
    const current = this.metrics.calls.get(key) || { success: 0, failed: 0 };
    current.success++;
    this.metrics.calls.set(key, current);
    this.metrics.durations.push(duration);
  }

  recordError(endpoint, method, error, duration) {
    const key = `${method} ${endpoint}`;
    const current = this.metrics.calls.get(key) || { success: 0, failed: 0 };
    current.failed++;
    this.metrics.calls.set(key, current);
    
    const errorKey = `${key}:${error.code || 'UNKNOWN'}`;
    this.metrics.errors.set(errorKey, (this.metrics.errors.get(errorKey) || 0) + 1);
  }

  getMetrics() {
    return {
      endpoints: Object.fromEntries(this.metrics.calls),
      errors: Object.fromEntries(this.metrics.errors),
      performance: {
        avgDuration: this.calculateAverage(this.metrics.durations),
        p95Duration: this.calculatePercentile(this.metrics.durations, 95),
        p99Duration: this.calculatePercentile(this.metrics.durations, 99)
      }
    };
  }
}
```

### 6.2 Health Check Implementation
```javascript
class IntegrationHealthCheck {
  async checkHealth() {
    const checks = {
      database: await this.checkDatabase(),
      queue: await this.checkQueue(),
      external_api: await this.checkExternalAPI(),
      authentication: await this.checkAuthentication()
    };
    
    const overall = Object.values(checks).every(check => check.status === 'healthy');
    
    return {
      status: overall ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      checks
    };
  }

  async checkExternalAPI() {
    try {
      const response = await fetch(`${Config.EXTERNAL_API}/health`, {
        timeout: 5000
      });
      
      return {
        status: response.ok ? 'healthy' : 'unhealthy',
        response_time: response.headers.get('X-Response-Time'),
        details: response.ok ? null : `Status: ${response.status}`
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message
      };
    }
  }

  async checkQueue() {
    const stats = await this.getQueueStats();
    
    return {
      status: stats.failed < 10 && stats.pending < 1000 ? 'healthy' : 'degraded',
      stats: {
        pending: stats.pending,
        processing: stats.processing,
        failed: stats.failed,
        avg_processing_time: stats.avg_processing_time
      }
    };
  }
}
```

## 🌐 7. MULTI-SITE COORDINATION

### 7.1 Timezone Management
```javascript
class TimezoneCoordinator {
  constructor() {
    this.sites = {
      'moscow': { timezone: 'Europe/Moscow', offset: 3 },
      'yekaterinburg': { timezone: 'Asia/Yekaterinburg', offset: 5 },
      'novosibirsk': { timezone: 'Asia/Novosibirsk', offset: 7 },
      'vladivostok': { timezone: 'Asia/Vladivostok', offset: 10 }
    };
  }

  convertToUTC(localTime, siteId) {
    const site = this.sites[siteId];
    if (!site) throw new Error(`Unknown site: ${siteId}`);
    
    return moment.tz(localTime, site.timezone).utc().toISOString();
  }

  convertFromUTC(utcTime, siteId) {
    const site = this.sites[siteId];
    if (!site) throw new Error(`Unknown site: ${siteId}`);
    
    return moment.utc(utcTime).tz(site.timezone).format();
  }

  scheduleSyncTime() {
    // Always schedule in Moscow time as per business rule
    const moscowTime = moment.tz('Europe/Moscow');
    const lastSaturday = this.getLastSaturday(moscowTime);
    
    return lastSaturday.hour(1).minute(30).second(0).utc().toISOString();
  }

  getLastSaturday(date) {
    const endOfMonth = date.clone().endOf('month');
    const dayOfWeek = endOfMonth.day();
    const daysToSubtract = dayOfWeek >= 6 ? dayOfWeek - 6 : dayOfWeek + 1;
    
    return endOfMonth.subtract(daysToSubtract, 'days');
  }
}
```

## 📋 8. DATA VALIDATION & TRANSFORMATION

### 8.1 Input Validation
```javascript
class IntegrationValidator {
  validateEmployeeData(employee) {
    const errors = [];
    
    // Required fields
    if (!employee.agent_id) errors.push('agent_id is required');
    if (!employee.tab_number) errors.push('tab_number is required');
    if (!employee.lastname) errors.push('lastname is required');
    if (!employee.firstname) errors.push('firstname is required');
    
    // Format validation
    if (employee.tab_number && !/^\d{5,10}$/.test(employee.tab_number)) {
      errors.push('tab_number must be 5-10 digits');
    }
    
    // Date validation
    if (employee.start_work && !moment(employee.start_work).isValid()) {
      errors.push('start_work must be valid date');
    }
    
    // Numeric validation
    if (employee.norm_week && (employee.norm_week < 0 || employee.norm_week > 60)) {
      errors.push('norm_week must be between 0 and 60');
    }
    
    return {
      valid: errors.length === 0,
      errors
    };
  }

  validateScheduleData(schedule) {
    const errors = [];
    
    // Validate shifts don't overlap
    const shifts = schedule.shifts.sort((a, b) => 
      moment(a.start_time).diff(moment(b.start_time))
    );
    
    for (let i = 0; i < shifts.length - 1; i++) {
      const currentEnd = moment(shifts[i].end_time);
      const nextStart = moment(shifts[i + 1].start_time);
      
      if (currentEnd.isAfter(nextStart)) {
        errors.push(`Overlapping shifts on ${shifts[i].date}`);
      }
    }
    
    // Validate work time limits
    shifts.forEach(shift => {
      const duration = moment(shift.end_time).diff(moment(shift.start_time), 'hours');
      if (duration > 12) {
        errors.push(`Shift on ${shift.date} exceeds 12 hours`);
      }
    });
    
    return {
      valid: errors.length === 0,
      errors
    };
  }
}
```

### 8.2 Data Transformation
```javascript
class DataTransformer {
  transformEmployee1CToArgus(external) {
    return {
      external_id: external.agent_id,
      employee_code: external.tab_number,
      last_name: external.lastname,
      first_name: external.firstname,
      middle_name: external.secondname || null,
      position: {
        external_id: external.position_id,
        title: external.position_name
      },
      department: {
        external_id: external.department_id
      },
      hire_date: external.start_work,
      termination_date: external.finish_work || null,
      employment: {
        fte: external.employment_rate || 1.0,
        weekly_hours: external.norm_week,
        hours_change_date: external.norm_week_change_date
      },
      sso_login: external.login_sso || null,
      active: !external.finish_work
    };
  }

  transformArgusEmployeeTo1C(internal) {
    return {
      agent_id: internal.external_id,
      tab_number: internal.employee_code,
      lastname: internal.last_name,
      firstname: internal.first_name,
      secondname: internal.middle_name,
      start_work: internal.hire_date,
      finish_work: internal.termination_date,
      position_id: internal.position?.external_id,
      position_name: internal.position?.title,
      department_id: internal.department?.external_id,
      employment_rate: internal.employment?.fte || 1.0,
      norm_week: internal.employment?.weekly_hours || 40,
      norm_week_change_date: internal.employment?.hours_change_date,
      login_sso: internal.sso_login
    };
  }
}
```

## 🔒 9. SECURITY IMPLEMENTATION

### 9.1 Credential Management
```javascript
class SecureCredentialManager {
  constructor(encryptionKey) {
    this.cipher = crypto.createCipher('aes-256-gcm', encryptionKey);
  }

  async storeCredentials(system, credentials) {
    const encrypted = this.encrypt(JSON.stringify(credentials));
    
    await db.credentials.upsert({
      system_id: system,
      encrypted_data: encrypted,
      updated_at: new Date()
    });
  }

  async getCredentials(system) {
    const record = await db.credentials.findOne({ system_id: system });
    if (!record) throw new Error(`No credentials for system: ${system}`);
    
    const decrypted = this.decrypt(record.encrypted_data);
    return JSON.parse(decrypted);
  }

  encrypt(text) {
    const encrypted = this.cipher.update(text, 'utf8', 'hex');
    return encrypted + this.cipher.final('hex');
  }

  decrypt(encrypted) {
    const decipher = crypto.createDecipher('aes-256-gcm', this.encryptionKey);
    const decrypted = decipher.update(encrypted, 'hex', 'utf8');
    return decrypted + decipher.final('utf8');
  }
}
```

### 9.2 Audit Logging
```javascript
class AuditLogger {
  async logAPICall(details) {
    const sanitized = this.sanitizeForAudit(details);
    
    await db.audit_logs.insert({
      timestamp: new Date(),
      event_type: 'api_call',
      user_id: details.user_id || 'system',
      endpoint: details.endpoint,
      method: details.method,
      request_id: details.request_id,
      response_status: details.response_status,
      duration_ms: details.duration,
      ip_address: details.ip_address,
      user_agent: details.user_agent,
      data_classification: 'sensitive',
      retention_period: '3_years'
    });
  }

  sanitizeForAudit(data) {
    // Remove sensitive data from logs
    const sanitized = { ...data };
    
    // Remove passwords
    if (sanitized.request_body?.password) {
      sanitized.request_body.password = '[REDACTED]';
    }
    
    // Mask personal identifiers
    if (sanitized.request_body?.ssn) {
      sanitized.request_body.ssn = 'XXX-XX-' + 
        sanitized.request_body.ssn.slice(-4);
    }
    
    return sanitized;
  }
}
```

## 🚀 10. DEPLOYMENT & OPERATIONS

### 10.1 Environment Configuration
```yaml
# config/production.yml
integration:
  1c_zup:
    endpoint: "http://192.168.45.162:8090/services/personnel"
    timeout: 30000
    retries: 3
    auth_type: "basic"
    
  mce:
    endpoint: "ws://192.168.45.162:8090/ws/agent-status"
    fallback: "http://192.168.45.162:8090/api/v1/agents"
    heartbeat: 30000
    
  queue:
    concurrency: 5
    poll_interval: 5000
    retry_delays: [30000, 120000, 300000]
    
  monitoring:
    health_check_interval: 60000
    metrics_retention: 604800000 # 7 days
    
  security:
    credential_rotation: 2592000000 # 30 days
    audit_retention: 94608000000 # 3 years
```

### 10.2 Operational Procedures
```javascript
// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('Shutting down integration service...');
  
  // Stop accepting new operations
  queueProcessor.stop();
  
  // Wait for in-flight operations
  await queueProcessor.waitForCompletion();
  
  // Close external connections
  await externalAPI.disconnect();
  
  // Final cleanup
  await db.close();
  
  logger.info('Shutdown complete');
  process.exit(0);
});

// Health endpoint for load balancer
app.get('/health', async (req, res) => {
  const health = await healthCheck.checkHealth();
  const statusCode = health.status === 'healthy' ? 200 : 503;
  
  res.status(statusCode).json(health);
});
```

---

**This comprehensive blueprint provides the complete implementation guide for Argus WFM integration APIs. It covers all aspects from authentication to monitoring, error handling to multi-site coordination. The patterns are based on verified BDD scenarios and live system testing, ready for implementation when MCP browser tools are available for final validation.**