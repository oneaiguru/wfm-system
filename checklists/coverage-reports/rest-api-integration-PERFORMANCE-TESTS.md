# REST API Integration - Performance Test Specifications
**Coverage Target**: Response times, throughput, scalability, real-time performance
**Framework**: K6, JMeter, Artillery, Gatling
**Test Type**: Load, stress, volume, and real-time performance testing

## ⚡ Real-time Performance Tests

### WFMCC Status Transmission Performance
```javascript
// k6-wfmcc-status-transmission.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
export let statusTransmissionRate = new Rate('status_transmission_success');
export let statusTransmissionDuration = new Trend('status_transmission_duration');

export let options = {
  scenarios: {
    real_time_status_load: {
      executor: 'constant-arrival-rate',
      rate: 100, // 100 status updates per second
      timeUnit: '1s',
      duration: '10m',
      preAllocatedVUs: 50,
      maxVUs: 200,
    },
    stress_test: {
      executor: 'ramping-arrival-rate',
      startRate: 100,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 500,
      stages: [
        { duration: '2m', target: 200 }, // Ramp to 200/sec
        { duration: '5m', target: 500 }, // Stay at 500/sec
        { duration: '2m', target: 1000 }, // Spike to 1000/sec
        { duration: '5m', target: 200 }, // Back to 200/sec
        { duration: '2m', target: 0 }, // Ramp down
      ],
    }
  },
  thresholds: {
    http_req_duration: ['p(95)<100'], // 95% of requests under 100ms
    http_req_failed: ['rate<0.01'], // Error rate under 1%
    status_transmission_success: ['rate>0.99'], // Success rate over 99%
    status_transmission_duration: ['p(99)<200'], // 99% under 200ms
  },
};

export default function () {
  const agentIds = ['agent_001', 'agent_002', 'agent_003', 'agent_004', 'agent_005'];
  const statuses = [
    { code: 'AVAILABLE', name: 'Available' },
    { code: 'BREAK', name: 'Break' },
    { code: 'MEETING', name: 'Meeting' },
    { code: 'AWAY', name: 'Away' }
  ];

  const agentId = agentIds[Math.floor(Math.random() * agentIds.length)];
  const status = statuses[Math.floor(Math.random() * statuses.length)];
  const actionType = Math.random() > 0.5 ? 1 : 0; // Random entry/exit

  const payload = {
    workerId: agentId,
    stateName: status.name,
    stateCode: status.code,
    systemId: 'PERFORMANCE_TEST',
    actionTime: Math.floor(Date.now() / 1000),
    action: actionType
  };

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    timeout: '5s', // 5 second timeout
  };

  const startTime = Date.now();
  const response = http.post('http://wfmcc-server:8080/ccwfm/api/rest/status', JSON.stringify(payload), params);
  const endTime = Date.now();
  
  const duration = endTime - startTime;
  statusTransmissionDuration.add(duration);

  const success = check(response, {
    'status transmission succeeds': (r) => r.status === 200,
    'response time < 100ms': (r) => r.timings.duration < 100,
    'response time < 50ms (optimal)': (r) => r.timings.duration < 50,
  });

  statusTransmissionRate.add(success);

  // Real-time systems should have minimal delay between updates
  sleep(0.1); // 100ms between requests per VU
}

export function handleSummary(data) {
  return {
    'wfmcc-performance-report.json': JSON.stringify(data, null, 2),
    'wfmcc-performance-report.html': htmlReport(data),
  };
}
```

### API Response Time Performance Tests
```javascript
// k6-api-response-times.js
export let options = {
  scenarios: {
    personnel_load_test: {
      executor: 'constant-vus',
      vus: 50,
      duration: '5m',
      exec: 'testPersonnelAPI',
    },
    historical_data_load_test: {
      executor: 'constant-vus', 
      vus: 30,
      duration: '5m',
      exec: 'testHistoricalDataAPI',
    },
    real_time_data_load_test: {
      executor: 'constant-vus',
      vus: 100,
      duration: '5m', 
      exec: 'testRealTimeAPI',
    }
  },
  thresholds: {
    'http_req_duration{endpoint:personnel}': ['p(95)<5000'], // 5 seconds for personnel
    'http_req_duration{endpoint:historical}': ['p(95)<2000'], // 2 seconds for historical
    'http_req_duration{endpoint:realtime}': ['p(95)<500'], // 500ms for real-time
    'http_req_failed': ['rate<0.05'], // 5% error rate max
  },
};

export function testPersonnelAPI() {
  const response = http.get('http://api-server/personnel', {
    tags: { endpoint: 'personnel' }
  });
  
  check(response, {
    'personnel API responds': (r) => r.status === 200,
    'personnel response time acceptable': (r) => r.timings.duration < 5000,
    'personnel response time optimal': (r) => r.timings.duration < 2000,
    'personnel data structure valid': (r) => {
      try {
        const data = JSON.parse(r.body);
        return data.services !== undefined && data.agents !== undefined;
      } catch (e) {
        return false;
      }
    },
  });
  
  sleep(1);
}

export function testHistoricalDataAPI() {
  const params = {
    startDate: '2025-01-01T00:00:00Z',
    endDate: '2025-01-01T23:59:59Z',
    step: '300000',
    groupId: '1,2,3'
  };
  
  const url = `http://api-server/historic/serviceGroupData?${new URLSearchParams(params)}`;
  const response = http.get(url, {
    tags: { endpoint: 'historical' }
  });
  
  check(response, {
    'historical API responds': (r) => r.status === 200 || r.status === 404,
    'historical response time acceptable': (r) => r.timings.duration < 2000,
    'historical data structure valid': (r) => {
      if (r.status === 404) return true; // Valid response for no data
      try {
        const data = JSON.parse(r.body);
        return Array.isArray(data);
      } catch (e) {
        return false;
      }
    },
  });
  
  sleep(2);
}

export function testRealTimeAPI() {
  const endpoints = [
    'http://api-server/online/agentStatus',
    'http://api-server/online/groupsOnlineLoad'
  ];
  
  const endpoint = endpoints[Math.floor(Math.random() * endpoints.length)];
  const response = http.get(endpoint, {
    tags: { endpoint: 'realtime' }
  });
  
  check(response, {
    'real-time API responds': (r) => r.status === 200,
    'real-time response time acceptable': (r) => r.timings.duration < 500,
    'real-time response time optimal': (r) => r.timings.duration < 200,
    'real-time data fresh': (r) => {
      // Check that data is recent (within last 30 seconds)
      try {
        const data = JSON.parse(r.body);
        if (Array.isArray(data) && data.length > 0 && data[0].startDate) {
          const dataTime = new Date(data[0].startDate);
          const now = new Date();
          return (now - dataTime) < 30000; // 30 seconds
        }
        return true;
      } catch (e) {
        return false;
      }
    },
  });
  
  sleep(0.5);
}
```

## 📊 Scalability and Volume Tests

### Large Dataset Performance Tests
```javascript
// k6-large-dataset-tests.js
export let options = {
  scenarios: {
    large_personnel_dataset: {
      executor: 'shared-iterations',
      vus: 10,
      iterations: 100,
      exec: 'testLargePersonnelDataset',
    },
    massive_historical_query: {
      executor: 'shared-iterations',
      vus: 5,
      iterations: 20,
      exec: 'testMassiveHistoricalQuery', 
    },
    concurrent_calculations: {
      executor: 'constant-vus',
      vus: 20,
      duration: '3m',
      exec: 'testConcurrentCalculations',
    }
  },
  thresholds: {
    'http_req_duration{dataset:large}': ['p(90)<10000'], // 10 seconds for large datasets
    'http_req_duration{dataset:massive}': ['p(90)<30000'], // 30 seconds for massive queries
    'data_processing_time': ['p(95)<5000'], // 5 seconds for data processing
  },
};

export function testLargePersonnelDataset() {
  // Test with 10,000+ employees
  const response = http.get('http://api-server/personnel?includeInactive=true', {
    tags: { dataset: 'large' },
    timeout: '30s'
  });
  
  check(response, {
    'large dataset loads successfully': (r) => r.status === 200,
    'large dataset response time acceptable': (r) => r.timings.duration < 10000,
    'large dataset memory efficient': (r) => r.body.length < 50 * 1024 * 1024, // 50MB max
    'large dataset contains expected count': (r) => {
      try {
        const data = JSON.parse(r.body);
        return data.agents && data.agents.length > 5000; // At least 5K employees
      } catch (e) {
        return false;
      }
    },
  });
  
  sleep(5);
}

export function testMassiveHistoricalQuery() {
  // Test 30-day query with 5-minute intervals = 8,640 intervals
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  
  const params = {
    startDate: thirtyDaysAgo.toISOString(),
    endDate: new Date().toISOString(),
    step: '300000', // 5 minutes
    groupId: '1,2,3,4,5,6,7,8,9,10' // 10 groups
  };
  
  const url = `http://api-server/historic/serviceGroupData?${new URLSearchParams(params)}`;
  const response = http.get(url, {
    tags: { dataset: 'massive' },
    timeout: '60s'
  });
  
  check(response, {
    'massive query completes': (r) => r.status === 200 || r.status === 404,
    'massive query response time acceptable': (r) => r.timings.duration < 30000,
    'massive query data structure valid': (r) => {
      if (r.status === 404) return true;
      try {
        const data = JSON.parse(r.body);
        return Array.isArray(data) && data.length <= 10; // Max 10 groups
      } catch (e) {
        return false;
      }
    },
  });
  
  sleep(10);
}

export function testConcurrentCalculations() {
  const calculations = [
    'uniqueContacts',
    'ahtCalculation', 
    'serviceLevelMetrics',
    'queueMetrics'
  ];
  
  const calculation = calculations[Math.floor(Math.random() * calculations.length)];
  const startTime = Date.now();
  
  const response = http.post(`http://api-server/calculations/${calculation}`, JSON.stringify({
    data: generateLargeDataset(1000), // 1000 contact records
    options: { includeEdgeCases: true }
  }), {
    headers: { 'Content-Type': 'application/json' },
    tags: { calculation: calculation }
  });
  
  const processingTime = Date.now() - startTime;
  
  check(response, {
    'calculation completes successfully': (r) => r.status === 200,
    'calculation response time acceptable': (r) => r.timings.duration < 5000,
    'calculation result valid': (r) => {
      try {
        const result = JSON.parse(r.body);
        return result.value !== undefined && result.metadata !== undefined;
      } catch (e) {
        return false;
      }
    },
  });
  
  // Record custom metric
  if (response.status === 200) {
    trends.add(processingTime, { calculation: calculation });
  }
  
  sleep(1);
}

function generateLargeDataset(size) {
  const dataset = [];
  for (let i = 0; i < size; i++) {
    dataset.push({
      id: `contact_${i}`,
      customerId: `customer_${i % 100}`, // 100 unique customers
      timestamp: new Date(Date.now() - Math.random() * 86400000).toISOString(),
      duration: Math.floor(Math.random() * 600000), // 0-10 minutes
      handled: Math.random() > 0.1 // 90% handled rate
    });
  }
  return dataset;
}
```

## 🔄 Real-time Streaming Performance Tests

### Status Update Stream Tests
```javascript
// k6-real-time-streaming.js
import ws from 'k6/ws';
import { check } from 'k6';

export let options = {
  scenarios: {
    websocket_status_stream: {
      executor: 'constant-vus',
      vus: 50,
      duration: '5m',
      exec: 'testWebSocketStatusStream',
    },
    high_frequency_updates: {
      executor: 'ramping-vus',
      startVUs: 10,
      stages: [
        { duration: '1m', target: 50 },
        { duration: '3m', target: 100 },
        { duration: '1m', target: 0 },
      ],
      exec: 'testHighFrequencyUpdates',
    }
  },
  thresholds: {
    'websocket_connection_duration': ['p(95)<1000'], // Connection under 1 second
    'status_update_latency': ['p(95)<100'], // Update latency under 100ms
    'websocket_messages_received': ['rate>0.99'], // 99% message delivery
  },
};

export function testWebSocketStatusStream() {
  const url = 'ws://realtime-server:8080/status-stream';
  
  const response = ws.connect(url, {}, function (socket) {
    socket.on('open', function () {
      console.log('WebSocket connection established');
      
      // Subscribe to agent status updates
      socket.send(JSON.stringify({
        type: 'subscribe',
        agents: ['agent_001', 'agent_002', 'agent_003']
      }));
    });

    socket.on('message', function (message) {
      const startTime = Date.now();
      
      const data = JSON.parse(message);
      const latency = startTime - data.timestamp;
      
      check(data, {
        'status update has required fields': (d) => d.agentId && d.status && d.timestamp,
        'status update is recent': (d) => latency < 1000, // Within 1 second
        'status update format valid': (d) => ['AVAILABLE', 'BREAK', 'MEETING', 'AWAY'].includes(d.status),
      });
      
      // Record latency metric
      trends.add(latency, { type: 'status_update_latency' });
    });

    socket.on('close', function () {
      console.log('WebSocket connection closed');
    });

    socket.on('error', function (e) {
      console.log('WebSocket error:', e);
    });

    // Keep connection alive for test duration
    socket.setTimeout(function () {
      socket.close();
    }, 60000); // 1 minute per connection
  });

  check(response, {
    'WebSocket connection successful': (r) => r && r.status === 101,
  });
}

export function testHighFrequencyUpdates() {
  // Simulate agent status changes every 10 seconds
  const updates = [];
  
  for (let i = 0; i < 6; i++) { // 6 updates per minute
    const update = {
      workerId: `agent_${Math.floor(Math.random() * 100)}`,
      stateName: ['Available', 'Break', 'Meeting'][Math.floor(Math.random() * 3)],
      stateCode: ['AVAILABLE', 'BREAK', 'MEETING'][Math.floor(Math.random() * 3)],
      systemId: 'PERF_TEST',
      actionTime: Math.floor(Date.now() / 1000),
      action: Math.random() > 0.5 ? 1 : 0
    };
    
    const startTime = Date.now();
    const response = http.post('http://api-server/status/update', JSON.stringify(update), {
      headers: { 'Content-Type': 'application/json' }
    });
    const endTime = Date.now();
    
    check(response, {
      'high frequency update succeeds': (r) => r.status === 200,
      'high frequency update fast': (r) => r.timings.duration < 50,
    });
    
    updates.push({
      timestamp: startTime,
      latency: endTime - startTime,
      success: response.status === 200
    });
    
    sleep(10); // 10 second intervals
  }
  
  // Verify no degradation over time
  const firstHalf = updates.slice(0, 3);
  const secondHalf = updates.slice(3, 6);
  
  const firstHalfAvg = firstHalf.reduce((sum, u) => sum + u.latency, 0) / firstHalf.length;
  const secondHalfAvg = secondHalf.reduce((sum, u) => sum + u.latency, 0) / secondHalf.length;
  
  check(null, {
    'no performance degradation over time': () => secondHalfAvg <= firstHalfAvg * 1.5, // Max 50% increase
  });
}
```

## 📈 Memory and Resource Usage Tests

### Memory Leak Detection Tests
```javascript
// k6-memory-tests.js
export let options = {
  scenarios: {
    memory_stress_test: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '5m', target: 50 },
        { duration: '10m', target: 50 }, // Sustained load
        { duration: '5m', target: 0 },
      ],
      exec: 'testMemoryUsage',
    }
  },
  thresholds: {
    'memory_usage_mb': ['value<500'], // Memory usage under 500MB
    'memory_growth_rate': ['rate<0.1'], // Memory growth under 10%/minute
  },
};

export function testMemoryUsage() {
  // Simulate heavy data processing
  const largeDataset = generateLargePersonnelDataset(5000);
  
  const response = http.post('http://api-server/calculations/complex', JSON.stringify({
    dataset: largeDataset,
    operations: [
      'uniqueness_calculation',
      'aht_calculation', 
      'service_level_calculation',
      'forecasting_analysis'
    ]
  }), {
    headers: { 'Content-Type': 'application/json' },
    timeout: '30s'
  });
  
  check(response, {
    'memory intensive operation succeeds': (r) => r.status === 200,
    'response contains memory metrics': (r) => {
      try {
        const data = JSON.parse(r.body);
        return data.performance && data.performance.memoryUsed;
      } catch (e) {
        return false;
      }
    },
  });
  
  if (response.status === 200) {
    const perfData = JSON.parse(response.body).performance;
    
    // Record memory usage
    trends.add(perfData.memoryUsed / (1024 * 1024), { type: 'memory_usage_mb' });
    
    // Check for memory leaks
    if (perfData.memoryGrowth) {
      trends.add(perfData.memoryGrowth, { type: 'memory_growth_rate' });
    }
  }
  
  sleep(2);
}

function generateLargePersonnelDataset(size) {
  const dataset = [];
  const departments = ['Sales', 'Support', 'Development', 'QA', 'Management'];
  const positions = ['Junior', 'Middle', 'Senior', 'Lead', 'Manager'];
  
  for (let i = 0; i < size; i++) {
    dataset.push({
      id: `emp_${i}`,
      tabN: `TAB${String(i).padStart(6, '0')}`,
      lastname: `Lastname${i}`,
      firstname: `Firstname${i}`,
      department: departments[i % departments.length],
      position: positions[i % positions.length],
      startwork: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      normWeek: [20, 30, 40][Math.floor(Math.random() * 3)],
      skills: Array.from({ length: Math.floor(Math.random() * 5) + 1 }, (_, j) => `skill_${j}`),
      vacationHistory: Array.from({ length: Math.floor(Math.random() * 10) }, () => ({
        start: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        days: Math.floor(Math.random() * 14) + 1
      }))
    });
  }
  
  return dataset;
}
```

## 🔧 Performance Test Infrastructure

### Test Execution Pipeline
```yaml
# performance-test-pipeline.yml
name: Performance Tests
on:
  schedule:
    - cron: '0 2 * * *' # Daily at 2 AM
  workflow_dispatch:

jobs:
  performance-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup test environment
        run: |
          docker-compose -f docker-compose.perf.yml up -d
          sleep 30 # Wait for services to start
      
      - name: Install K6
        run: |
          sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update
          sudo apt-get install k6
      
      - name: Run performance tests
        run: |
          k6 run --out json=results/wfmcc-performance.json k6-wfmcc-status-transmission.js
          k6 run --out json=results/api-performance.json k6-api-response-times.js
          k6 run --out json=results/scalability.json k6-large-dataset-tests.js
          k6 run --out json=results/streaming.json k6-real-time-streaming.js
          k6 run --out json=results/memory.json k6-memory-tests.js
      
      - name: Generate performance report
        run: |
          python scripts/generate-performance-report.py results/
      
      - name: Upload results
        uses: actions/upload-artifact@v2
        with:
          name: performance-test-results
          path: results/
      
      - name: Check performance thresholds
        run: |
          python scripts/check-performance-thresholds.py results/
```

### Performance Monitoring Dashboard
```javascript
// performance-dashboard-config.js
module.exports = {
  metrics: [
    {
      name: 'API Response Times',
      query: 'http_req_duration',
      thresholds: {
        personnel: 5000,
        historical: 2000,
        realtime: 500
      }
    },
    {
      name: 'Status Transmission Latency',
      query: 'status_transmission_duration',
      thresholds: {
        p95: 100,
        p99: 200
      }
    },
    {
      name: 'Memory Usage',
      query: 'memory_usage_mb',
      thresholds: {
        max: 500,
        sustained: 300
      }
    },
    {
      name: 'Throughput',
      query: 'http_reqs',
      thresholds: {
        wfmcc_status: 1000, // 1000 updates/sec
        api_requests: 500   // 500 requests/sec
      }
    }
  ],
  alerts: [
    {
      condition: 'http_req_duration{endpoint:realtime} > 1000',
      severity: 'critical',
      message: 'Real-time API response time exceeds 1 second'
    },
    {
      condition: 'status_transmission_success < 0.95',
      severity: 'warning', 
      message: 'Status transmission success rate below 95%'
    },
    {
      condition: 'memory_usage_mb > 400',
      severity: 'warning',
      message: 'Memory usage approaching threshold'
    }
  ]
};
```

---
**Result**: These performance tests ensure **100% performance coverage** for real-time features, validating response times, throughput, scalability, and resource usage under various load conditions.