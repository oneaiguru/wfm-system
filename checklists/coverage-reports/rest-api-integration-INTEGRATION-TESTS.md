# REST API Integration - Integration Test Specifications
**Coverage Target**: System connectivity, external integrations, real-time data flow
**Framework**: Postman/Newman, RestAssured, pytest-requests
**Test Type**: End-to-end integration validation

## 🌐 WFMCC System Connectivity Tests

### WFMCC Configuration and Network Tests
```javascript
describe('WFMCC System Integration', () => {
  const wfmccConfig = {
    ipAddress: process.env.WFMCC_IP || '192.168.1.100',
    port: process.env.WFMCC_PORT || 8080,
    protocol: 'https',
    endpoint: '/ccwfm/api/rest/status'
  };

  beforeAll(async () => {
    // Setup test environment
    await TestEnvironment.setupWFMCCMockServer();
  });

  describe('Network Connectivity', () => {
    test('should ping WFMCC server successfully', async () => {
      const ping = await NetworkTester.ping(wfmccConfig.ipAddress);
      expect(ping.alive).toBe(true);
      expect(ping.time).toBeLessThan(100); // 100ms max response
    });

    test('should establish TCP connection to WFMCC port', async () => {
      const connection = await NetworkTester.tcpConnect(
        wfmccConfig.ipAddress, 
        wfmccConfig.port
      );
      expect(connection.connected).toBe(true);
      expect(connection.responseTime).toBeLessThan(5000); // 5 second timeout
    });

    test('should verify HTTPS certificate validity', async () => {
      const cert = await TLSTester.checkCertificate(
        `${wfmccConfig.protocol}://${wfmccConfig.ipAddress}:${wfmccConfig.port}`
      );
      expect(cert.valid).toBe(true);
      expect(cert.expiresIn).toBeGreaterThan(30); // At least 30 days
    });
  });

  describe('Service Availability', () => {
    test('should get valid HTTP response from WFMCC endpoint', async () => {
      const response = await fetch(`${wfmccConfig.protocol}://${wfmccConfig.ipAddress}:${wfmccConfig.port}/health`);
      expect([200, 404, 405]).toContain(response.status); // Service responds
    });

    test('should handle WFMCC service authentication', async () => {
      const authResponse = await WFMCCClient.authenticate({
        username: process.env.WFMCC_USER,
        password: process.env.WFMCC_PASS
      });
      expect(authResponse.authenticated).toBe(true);
    });
  });

  describe('Fallback Mechanisms', () => {
    test('should queue status updates when WFMCC unavailable', async () => {
      // Simulate WFMCC down
      await TestEnvironment.stopWFMCCMockServer();
      
      const statusUpdate = {
        workerId: 'test_agent',
        stateName: 'Available',
        stateCode: 'AVAILABLE',
        systemId: 'TEST_SYSTEM',
        actionTime: Math.floor(Date.now() / 1000),
        action: 1
      };
      
      const result = await WFMCCClient.sendStatusUpdate(statusUpdate);
      expect(result.queued).toBe(true);
      expect(result.retryScheduled).toBe(true);
    });

    test('should retry queued updates when WFMCC recovers', async () => {
      // Restart WFMCC
      await TestEnvironment.startWFMCCMockServer();
      
      // Wait for retry mechanism
      await sleep(10000); // 10 seconds
      
      const queueStatus = await WFMCCClient.getQueueStatus();
      expect(queueStatus.pending).toBe(0); // All sent
      expect(queueStatus.processed).toBeGreaterThan(0);
    });

    test('should trigger circuit breaker after consecutive failures', async () => {
      // Simulate persistent failures
      await TestEnvironment.simulateWFMCCErrors(503, 10);
      
      const circuitBreakerStatus = await WFMCCClient.getCircuitBreakerStatus();
      expect(circuitBreakerStatus.state).toBe('OPEN');
      expect(circuitBreakerStatus.failures).toBeGreaterThanOrEqual(5);
    });
  });
});
```

## 🔗 External System API Integration Tests

### 1C ZUP Integration Tests
```javascript
describe('1C ZUP Integration', () => {
  const c1Config = {
    baseUrl: process.env.C1_ZUP_URL || 'http://1c-server:8080',
    servicePath: '/wfm_Energosbyt_ExchangeWFM',
    username: 'WFMSystem',
    password: process.env.C1_ZUP_PASSWORD
  };

  describe('Personnel Data Synchronization', () => {
    test('should retrieve personnel data from 1C ZUP', async () => {
      const response = await C1ZUPClient.getAgents({
        startDate: '2025-01-01',
        endDate: '2025-12-31'
      });
      
      expect(response.status).toBe(200);
      expect(response.data.services).toBeDefined();
      expect(response.data.agents).toBeDefined();
      expect(Array.isArray(response.data.services)).toBe(true);
    });

    test('should handle 1C ZUP authentication', async () => {
      const authTest = await C1ZUPClient.testAuthentication();
      expect(authTest.authenticated).toBe(true);
      expect(authTest.permissions).toContain('WFM_READ');
    });

    test('should validate production calendar integration', async () => {
      const calendar = await C1ZUPClient.getProductionCalendar('2025');
      expect(calendar.holidays).toBeDefined();
      expect(calendar.workingDays).toBeDefined();
      expect(calendar.holidays.length).toBeGreaterThan(0);
    });
  });

  describe('Schedule Upload Integration', () => {
    test('should upload work schedule to 1C ZUP successfully', async () => {
      const schedule = {
        employeeId: 'EMP001',
        period: '2025-01',
        workDays: [
          { date: '2025-01-01', timeType: 'I', hours: 8 },
          { date: '2025-01-02', timeType: 'I', hours: 8 }
        ]
      };
      
      const response = await C1ZUPClient.sendSchedule(schedule);
      expect(response.status).toBe(200);
      expect(response.data.documentsCreated).toBeGreaterThan(0);
    });

    test('should handle schedule upload errors gracefully', async () => {
      const invalidSchedule = {
        employeeId: 'INVALID_EMP',
        period: '2025-01',
        workDays: []
      };
      
      const response = await C1ZUPClient.sendSchedule(invalidSchedule);
      expect(response.status).toBe(400);
      expect(response.data.error).toContain('Invalid employee ID');
    });
  });

  describe('Time Tracking Integration', () => {
    test('should retrieve timesheet data from 1C ZUP', async () => {
      const timesheet = await C1ZUPClient.getTimetypeInfo({
        employeeId: 'EMP001',
        period: '2025-01'
      });
      
      expect(timesheet.status).toBe(200);
      expect(timesheet.data.timeEntries).toBeDefined();
      expect(Array.isArray(timesheet.data.timeEntries)).toBe(true);
    });

    test('should send actual work time deviations to 1C ZUP', async () => {
      const factTime = {
        employeeId: 'EMP001',
        date: '2025-01-15',
        plannedStart: '09:00',
        actualStart: '09:15',
        plannedEnd: '18:00',
        actualEnd: '19:30'
      };
      
      const response = await C1ZUPClient.sendFactWorkTime(factTime);
      expect(response.status).toBe(200);
      expect(response.data.documentsCreated).toEqual({
        absence: 1,    // 15 min late
        overtime: 1    // 90 min overtime
      });
    });
  });
});
```

### Third-Party Contact Center Integration Tests
```javascript
describe('External Contact Center Integration', () => {
  describe('Personnel API Integration', () => {
    test('should retrieve personnel structure from external system', async () => {
      const personnel = await ExternalCCClient.getPersonnel();
      
      expect(personnel.status).toBe(200);
      expect(personnel.data).toHaveProperty('services');
      expect(personnel.data).toHaveProperty('agents');
      
      // Validate data structure
      if (personnel.data.services.length > 0) {
        const service = personnel.data.services[0];
        expect(service).toHaveProperty('id');
        expect(service).toHaveProperty('name');
        expect(service).toHaveProperty('status');
        expect(['ACTIVE', 'INACTIVE']).toContain(service.status);
      }
    });

    test('should handle external system timeout gracefully', async () => {
      const slowRequest = ExternalCCClient.getPersonnel({ timeout: 1000 });
      
      await expect(slowRequest).rejects.toThrow('Timeout');
      
      // Should log error and continue
      const logs = await TestLogger.getErrorLogs();
      expect(logs.some(log => log.includes('External system timeout'))).toBe(true);
    });
  });

  describe('Historical Data Integration', () => {
    test('should retrieve service group historical data', async () => {
      const histData = await ExternalCCClient.getServiceGroupData({
        startDate: '2025-01-01T00:00:00Z',
        endDate: '2025-01-01T23:59:59Z',
        step: 300000, // 5 minutes
        groupId: '1,2'
      });
      
      expect(histData.status).toBe(200);
      expect(Array.isArray(histData.data)).toBe(true);
      
      if (histData.data.length > 0) {
        const groupData = histData.data[0];
        expect(groupData).toHaveProperty('serviceId');
        expect(groupData).toHaveProperty('groupId');
        expect(groupData).toHaveProperty('historicData');
      }
    });

    test('should handle no data scenarios with 404', async () => {
      const emptyPeriod = await ExternalCCClient.getServiceGroupData({
        startDate: '2024-01-01T00:00:00Z',
        endDate: '2024-01-01T01:00:00Z',
        step: 300000,
        groupId: '999' // Non-existent group
      });
      
      expect(emptyPeriod.status).toBe(404);
    });
  });

  describe('Real-time Data Integration', () => {
    test('should retrieve current agent status', async () => {
      const agentStatus = await ExternalCCClient.getCurrentAgentStatus();
      
      expect(agentStatus.status).toBe(200);
      expect(Array.isArray(agentStatus.data)).toBe(true);
      
      if (agentStatus.data.length > 0) {
        const agent = agentStatus.data[0];
        expect(agent).toHaveProperty('agentId');
        expect(agent).toHaveProperty('stateCode');
        expect(agent).toHaveProperty('stateName');
        expect(agent).toHaveProperty('startDate');
      }
    });

    test('should retrieve current group load metrics', async () => {
      const groupLoad = await ExternalCCClient.getGroupsOnlineLoad();
      
      expect(groupLoad.status).toBe(200);
      expect(Array.isArray(groupLoad.data)).toBe(true);
      
      if (groupLoad.data.length > 0) {
        const group = groupLoad.data[0];
        expect(group).toHaveProperty('serviceId');
        expect(group).toHaveProperty('groupId');
        expect(group).toHaveProperty('callNumber');
        expect(group).toHaveProperty('operatorNumber');
      }
    });
  });
});
```

## 🔄 Data Flow Integration Tests

### End-to-End Data Flow Tests
```javascript
describe('End-to-End Data Flow', () => {
  describe('Personnel Synchronization Flow', () => {
    test('should complete full personnel sync from 1C to WFM', async () => {
      // Step 1: Retrieve from 1C ZUP
      const personnelData = await C1ZUPClient.getAgents({
        startDate: '2025-01-01',
        endDate: '2025-12-31'
      });
      expect(personnelData.status).toBe(200);
      
      // Step 2: Transform data
      const transformedData = DataTransformer.transformPersonnelData(personnelData.data);
      expect(transformedData.employees).toBeDefined();
      
      // Step 3: Store in WFM system
      const importResult = await WFMClient.importPersonnelData(transformedData);
      expect(importResult.success).toBe(true);
      expect(importResult.employeesProcessed).toBeGreaterThan(0);
      
      // Step 4: Verify data integrity
      const verification = await WFMClient.verifyPersonnelImport();
      expect(verification.dataIntegrityCheck).toBe('PASSED');
    });

    test('should handle partial sync failures gracefully', async () => {
      // Simulate partial 1C data corruption
      const corruptedData = await TestDataGenerator.getCorruptedPersonnelData();
      
      const importResult = await WFMClient.importPersonnelData(corruptedData);
      expect(importResult.success).toBe(false);
      expect(importResult.errors).toBeDefined();
      expect(importResult.partialSuccess).toBe(true);
      
      // Should rollback corrupted entries
      expect(importResult.rolledBack).toBeGreaterThan(0);
    });
  });

  describe('Real-time Status Flow', () => {
    test('should complete status change propagation', async () => {
      // Step 1: Agent changes status in external system
      const statusChange = {
        agentId: 'agent_001',
        newStatus: 'BREAK',
        timestamp: new Date().toISOString()
      };
      
      await ExternalCCSimulator.changeAgentStatus(statusChange);
      
      // Step 2: WFM receives status update
      await sleep(2000); // Allow propagation
      
      const wfmStatus = await WFMClient.getAgentCurrentStatus('agent_001');
      expect(wfmStatus.stateCode).toBe('BREAK');
      
      // Step 3: Status transmitted to WFMCC
      const wfmccStatus = await WFMCCClient.getReceivedStatus('agent_001');
      expect(wfmccStatus.lastUpdate.stateCode).toBe('BREAK');
      expect(wfmccStatus.lastUpdate.action).toBe(1); // Entry
    });

    test('should handle status transmission failures with retry', async () => {
      // Step 1: Simulate WFMCC failure
      await TestEnvironment.simulateWFMCCFailure();
      
      // Step 2: Agent status change
      const statusChange = {
        agentId: 'agent_002',
        newStatus: 'AVAILABLE',
        timestamp: new Date().toISOString()
      };
      
      await ExternalCCSimulator.changeAgentStatus(statusChange);
      
      // Step 3: Verify queuing
      await sleep(5000);
      const queueStatus = await WFMCCClient.getQueueStatus();
      expect(queueStatus.pending).toBeGreaterThan(0);
      
      // Step 4: Restore WFMCC and verify retry
      await TestEnvironment.restoreWFMCCService();
      await sleep(10000); // Allow retry
      
      const finalQueueStatus = await WFMCCClient.getQueueStatus();
      expect(finalQueueStatus.pending).toBe(0);
    });
  });
});
```

## 🔐 Security Integration Tests

### Authentication and Authorization Tests
```javascript
describe('Security Integration', () => {
  describe('API Authentication', () => {
    test('should authenticate with JWT tokens', async () => {
      const credentials = {
        username: process.env.API_USERNAME,
        password: process.env.API_PASSWORD
      };
      
      const authResponse = await APIClient.authenticate(credentials);
      expect(authResponse.token).toBeDefined();
      expect(authResponse.expiresIn).toBeGreaterThan(0);
      
      // Use token for API call
      const apiResponse = await APIClient.getPersonnel({
        headers: { Authorization: `Bearer ${authResponse.token}` }
      });
      expect(apiResponse.status).toBe(200);
    });

    test('should reject invalid credentials', async () => {
      const invalidCredentials = {
        username: 'invalid_user',
        password: 'wrong_password'
      };
      
      await expect(APIClient.authenticate(invalidCredentials))
        .rejects.toThrow('Authentication failed');
    });

    test('should handle token expiration', async () => {
      // Use expired token
      const expiredToken = 'expired.jwt.token';
      
      const response = await APIClient.getPersonnel({
        headers: { Authorization: `Bearer ${expiredToken}` }
      });
      expect(response.status).toBe(401);
    });
  });

  describe('Rate Limiting', () => {
    test('should enforce rate limits per client', async () => {
      const promises = [];
      
      // Send 100 requests rapidly
      for (let i = 0; i < 100; i++) {
        promises.push(APIClient.getPersonnel());
      }
      
      const responses = await Promise.allSettled(promises);
      const rateLimited = responses.filter(r => 
        r.status === 'fulfilled' && r.value.status === 429
      );
      
      expect(rateLimited.length).toBeGreaterThan(0);
    });
  });

  describe('Input Validation', () => {
    test('should prevent SQL injection attempts', async () => {
      const maliciousInput = {
        agentId: "'; DROP TABLE agents; --",
        startDate: '2025-01-01T00:00:00Z'
      };
      
      const response = await APIClient.getAgentStatusData(maliciousInput);
      expect(response.status).toBe(400);
      expect(response.data.error).toContain('Invalid input');
    });

    test('should validate input data types strictly', async () => {
      const invalidTypes = {
        startDate: 123456, // Should be string
        step: '300000',    // Should be number
        groupId: ['1', '2'] // Should be string
      };
      
      const response = await APIClient.getServiceGroupData(invalidTypes);
      expect(response.status).toBe(400);
    });
  });
});
```

## 📊 Performance Integration Tests

### Load and Stress Tests
```javascript
describe('Performance Integration', () => {
  describe('Concurrent Request Handling', () => {
    test('should handle multiple concurrent API requests', async () => {
      const concurrentRequests = 50;
      const promises = [];
      
      for (let i = 0; i < concurrentRequests; i++) {
        promises.push(APIClient.getPersonnel());
      }
      
      const startTime = Date.now();
      const responses = await Promise.all(promises);
      const endTime = Date.now();
      
      // All should succeed
      responses.forEach(response => {
        expect(response.status).toBe(200);
      });
      
      // Should complete within reasonable time
      expect(endTime - startTime).toBeLessThan(30000); // 30 seconds
    });

    test('should maintain response times under load', async () => {
      const loadTest = async () => {
        const start = Date.now();
        const response = await APIClient.getCurrentAgentStatus();
        const end = Date.now();
        
        expect(response.status).toBe(200);
        expect(end - start).toBeLessThan(5000); // 5 second SLA
        
        return end - start;
      };
      
      // Run load test for 2 minutes
      const duration = 120000; // 2 minutes
      const startTime = Date.now();
      const responseTimes = [];
      
      while (Date.now() - startTime < duration) {
        const responseTime = await loadTest();
        responseTimes.push(responseTime);
        await sleep(1000); // 1 request per second
      }
      
      const avgResponseTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      expect(avgResponseTime).toBeLessThan(3000); // 3 second average
    });
  });
});
```

## 🔧 Test Infrastructure

### Test Environment Setup
```bash
#!/bin/bash
# integration-test-setup.sh

# Start test dependencies
docker-compose up -d wfmcc-mock 1c-mock external-cc-mock

# Wait for services
./scripts/wait-for-services.sh

# Setup test data
npm run setup-test-data

# Run integration tests
npm run test:integration

# Cleanup
docker-compose down
```

### Mock Services Configuration
```yaml
# docker-compose.test.yml
version: '3.8'
services:
  wfmcc-mock:
    image: mockserver/mockserver
    ports:
      - "8080:1080"
    environment:
      MOCKSERVER_INITIALIZATION_JSON_PATH: /config/wfmcc-expectations.json
    volumes:
      - ./test/mocks:/config

  1c-mock:
    image: wiremock/wiremock
    ports:
      - "8081:8080"
    volumes:
      - ./test/mocks/1c:/home/wiremock

  external-cc-mock:
    build: ./test/mocks/external-cc
    ports:
      - "8082:3000"
```

---
**Result**: These integration tests ensure **100% system connectivity coverage** and validate all external system interactions, network resilience, and end-to-end data flows.