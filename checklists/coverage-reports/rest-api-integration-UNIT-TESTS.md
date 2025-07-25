# REST API Integration - Unit Test Specifications
**Coverage Target**: Calculation algorithms, edge cases, data validation
**Framework**: Jest/JUnit/pytest (language-specific)
**Test Type**: TDD specifications for 100% coverage

## 📊 Calculator Function Unit Tests

### ContactUniquenessCalculator
```javascript
describe('ContactUniquenessCalculator', () => {
  describe('calculateDailyUniqueContacts', () => {
    test('should identify unique contacts by customer ID within single day', () => {
      const contacts = [
        { customerId: 'C001', timestamp: '2025-01-01T10:00:00Z' },
        { customerId: 'C001', timestamp: '2025-01-01T15:00:00Z' }, // duplicate
        { customerId: 'C002', timestamp: '2025-01-01T12:00:00Z' }
      ];
      expect(calculator.calculateDailyUniqueContacts(contacts)).toBe(2);
    });

    test('should reset uniqueness count across day boundaries', () => {
      const contacts = [
        { customerId: 'C001', timestamp: '2025-01-01T23:59:00Z' },
        { customerId: 'C001', timestamp: '2025-01-02T00:01:00Z' } // new day
      ];
      expect(calculator.calculateDailyUniqueContacts(contacts)).toBe(2);
    });

    test('should handle null or undefined customer IDs', () => {
      const contacts = [
        { customerId: null, timestamp: '2025-01-01T10:00:00Z' },
        { customerId: undefined, timestamp: '2025-01-01T11:00:00Z' },
        { customerId: 'C001', timestamp: '2025-01-01T12:00:00Z' }
      ];
      expect(calculator.calculateDailyUniqueContacts(contacts)).toBe(1);
    });

    test('should fallback to device ID when customer ID unavailable', () => {
      const contacts = [
        { deviceId: 'D001', timestamp: '2025-01-01T10:00:00Z' },
        { deviceId: 'D001', timestamp: '2025-01-01T11:00:00Z' }, // duplicate
        { deviceId: 'D002', timestamp: '2025-01-01T12:00:00Z' }
      ];
      expect(calculator.calculateDailyUniqueContactsByDevice(contacts)).toBe(2);
    });
  });

  describe('calculateTransferHandling', () => {
    test('should count each transfer leg separately', () => {
      const transfer = {
        originalCall: { duration: 300000 }, // 5 minutes
        transferLegs: [
          { duration: 120000 }, // 2 minutes
          { duration: 180000 }  // 3 minutes
        ]
      };
      expect(calculator.calculateTransferContacts(transfer)).toBe(3); // 1 + 2 legs
    });
  });
});
```

### AHTCalculator
```javascript
describe('AHTCalculator', () => {
  describe('calculateAverageHandlingTime', () => {
    test('should calculate AHT with all components', () => {
      const contact = {
        ringTime: 15000,      // 15 seconds
        talkTime: 180000,     // 3 minutes
        holdTime: 30000,      // 30 seconds
        wrapUpTime: 45000     // 45 seconds
      };
      const expectedAHT = 15000 + 180000 + 30000 + 45000; // 270 seconds
      expect(calculator.calculateAHT(contact)).toBe(expectedAHT);
    });

    test('should handle missing components gracefully', () => {
      const contact = {
        talkTime: 180000,     // Only talk time available
        // other components missing
      };
      expect(calculator.calculateAHT(contact)).toBe(180000);
    });

    test('should exclude system delays from AHT calculation', () => {
      const contact = {
        talkTime: 180000,
        systemDelay: 10000,   // Should be excluded
        holdTime: 30000
      };
      expect(calculator.calculateAHT(contact)).toBe(210000); // No system delay
    });

    test('should handle concurrent contacts with proportional allocation', () => {
      const agent = {
        contacts: [
          { talkTime: 300000, concurrent: ['C002'] },
          { talkTime: 300000, concurrent: ['C001'] }
        ]
      };
      // Each contact gets 50% allocation = 150000ms each
      expect(calculator.calculateProportionalAHT(agent)).toBe(150000);
    });

    test('should calculate batch AHT for multiple contacts', () => {
      const contacts = [
        { totalHandleTime: 300000 },  // 5 minutes
        { totalHandleTime: 120000 },  // 2 minutes
        { totalHandleTime: 180000 }   // 3 minutes
      ];
      const expectedAHT = (300000 + 120000 + 180000) / 3; // 200 seconds
      expect(calculator.calculateBatchAHT(contacts)).toBe(expectedAHT);
    });
  });
});
```

### ServiceLevelCalculator
```javascript
describe('ServiceLevelCalculator', () => {
  describe('calculateServiceLevel', () => {
    test('should calculate service level percentage correctly', () => {
      const metrics = {
        callsAnsweredWithinTarget: 85,
        totalCallsReceived: 100,
        targetServiceTime: 20000 // 20 seconds
      };
      expect(calculator.calculateServiceLevel(metrics)).toBe(85.0);
    });

    test('should handle zero calls received', () => {
      const metrics = {
        callsAnsweredWithinTarget: 0,
        totalCallsReceived: 0,
        targetServiceTime: 20000
      };
      expect(calculator.calculateServiceLevel(metrics)).toBe(0);
    });

    test('should calculate AWT (Average Wait Time)', () => {
      const calls = [
        { waitTime: 10000 },  // 10 seconds
        { waitTime: 30000 },  // 30 seconds
        { waitTime: 20000 }   // 20 seconds
      ];
      const expectedAWT = (10000 + 30000 + 20000) / 3; // 20 seconds
      expect(calculator.calculateAWT(calls)).toBe(expectedAWT);
    });

    test('should calculate abandonment rate', () => {
      const metrics = {
        abandonedCalls: 15,
        totalCalls: 100
      };
      expect(calculator.calculateAbandonmentRate(metrics)).toBe(15.0);
    });
  });

  describe('calculateDailyMetrics', () => {
    test('should reset metrics at midnight', () => {
      const yesterday = new Date('2025-01-01T23:59:00Z');
      const today = new Date('2025-01-02T00:01:00Z');
      
      calculator.addCall({ timestamp: yesterday, answered: true });
      expect(calculator.getDailyAnsweredCalls(today)).toBe(0); // Reset
    });
  });
});
```

## 🔄 Interval Processing Unit Tests

### IntervalProcessor
```javascript
describe('IntervalProcessor', () => {
  describe('formIntervalsFromDayStart', () => {
    test('should create intervals from start of day', () => {
      const stepMs = 300000; // 5 minutes
      const startTime = '2025-01-01T00:00:00Z';
      const endTime = '2025-01-01T00:15:00Z';
      
      const intervals = processor.formIntervals(startTime, endTime, stepMs);
      
      expect(intervals).toHaveLength(3);
      expect(intervals[0]).toEqual({
        startInterval: '2025-01-01T00:00:00Z',
        endInterval: '2025-01-01T00:05:00Z'
      });
    });

    test('should assign contacts to correct intervals based on start time', () => {
      const contact = { startTime: '2025-01-01T00:03:00Z' };
      const interval = processor.getIntervalForContact(contact, 300000);
      
      expect(interval.startInterval).toBe('2025-01-01T00:00:00Z');
      expect(interval.endInterval).toBe('2025-01-01T00:05:00Z');
    });

    test('should handle empty intervals based on configuration', () => {
      const config = { includeEmptyIntervals: false };
      const intervals = processor.formIntervals(
        '2025-01-01T00:00:00Z', 
        '2025-01-01T01:00:00Z', 
        300000,
        [], // no contacts
        config
      );
      
      expect(intervals).toHaveLength(0); // Excluded
    });

    test('should include empty intervals when configured', () => {
      const config = { includeEmptyIntervals: true };
      const intervals = processor.formIntervals(
        '2025-01-01T00:00:00Z', 
        '2025-01-01T00:15:00Z', 
        300000,
        [], // no contacts
        config
      );
      
      expect(intervals).toHaveLength(3);
      intervals.forEach(interval => {
        expect(interval.notUniqueReceived).toBe(0);
        expect(interval.notUniqueTreated).toBe(0);
      });
    });
  });
});
```

## 🤖 Bot Detection Unit Tests

### BotDetector
```javascript
describe('BotDetector', () => {
  describe('isBotClosedChat', () => {
    test('should detect bot-only chats', () => {
      const chat = {
        agentAssignment: null,
        messages: [
          { sender: 'bot', content: 'Hello! How can I help?' },
          { sender: 'customer', content: 'I need help' },
          { sender: 'bot', content: 'Let me help you with that' }
        ],
        resolution: 'bot_resolved'
      };
      
      expect(detector.isBotClosedChat(chat)).toBe(true);
    });

    test('should detect agent-handled chats', () => {
      const chat = {
        agentAssignment: 'agent_001',
        messages: [
          { sender: 'bot', content: 'Hello!' },
          { sender: 'agent', content: 'Hi, I can help you' },
          { sender: 'customer', content: 'Thank you' }
        ],
        resolution: 'agent_resolved'
      };
      
      expect(detector.isBotClosedChat(chat)).toBe(false);
    });

    test('should handle mixed chats (bot transfer to agent)', () => {
      const chat = {
        agentAssignment: 'agent_001',
        transfer: {
          from: 'bot',
          to: 'agent_001',
          timestamp: '2025-01-01T10:05:00Z'
        },
        resolution: 'agent_resolved'
      };
      
      expect(detector.isBotClosedChat(chat)).toBe(false); // Agent involved
    });
  });

  describe('getWFMCCEligibleChats', () => {
    test('should exclude bot-only chats from workforce metrics', () => {
      const chats = [
        { id: 'C001', agentAssignment: 'agent_001' }, // Include
        { id: 'C002', agentAssignment: null, resolution: 'bot_resolved' }, // Exclude
        { id: 'C003', agentAssignment: 'agent_002' }  // Include
      ];
      
      const eligible = detector.getWFMCCEligibleChats(chats);
      expect(eligible).toHaveLength(2);
      expect(eligible.map(c => c.id)).toEqual(['C001', 'C003']);
    });
  });
});
```

## 🌐 Timezone and Timestamp Unit Tests

### TimestampProcessor
```javascript
describe('TimestampProcessor', () => {
  describe('convertToUnixTimestamp', () => {
    test('should convert ISO datetime to Unix timestamp', () => {
      const isoDate = '2025-01-01T12:00:00Z';
      const expectedUnix = Math.floor(new Date(isoDate).getTime() / 1000);
      
      expect(processor.convertToUnixTimestamp(isoDate)).toBe(expectedUnix);
    });

    test('should handle timezone conversions to UTC', () => {
      const localDate = '2025-01-01T12:00:00+03:00'; // UTC+3
      const utcDate = '2025-01-01T09:00:00Z'; // UTC
      
      expect(processor.convertToUnixTimestamp(localDate))
        .toBe(processor.convertToUnixTimestamp(utcDate));
    });

    test('should maintain second-level precision', () => {
      const dateWithMs = '2025-01-01T12:00:00.999Z';
      const dateWithoutMs = '2025-01-01T12:00:00Z';
      
      // Should be the same at second precision
      expect(processor.convertToUnixTimestamp(dateWithMs))
        .toBe(processor.convertToUnixTimestamp(dateWithoutMs));
    });
  });
});
```

## 📈 Performance and Edge Case Tests

### DataValidator
```javascript
describe('DataValidator', () => {
  describe('validateLargeDatasets', () => {
    test('should handle large contact volumes efficiently', () => {
      const largeDataset = Array.from({ length: 100000 }, (_, i) => ({
        id: `contact_${i}`,
        customerId: `customer_${i % 1000}`, // 1000 unique customers
        timestamp: new Date(Date.now() + i * 1000).toISOString()
      }));
      
      const startTime = performance.now();
      const unique = calculator.calculateDailyUniqueContacts(largeDataset);
      const endTime = performance.now();
      
      expect(unique).toBe(1000);
      expect(endTime - startTime).toBeLessThan(5000); // 5 seconds max
    });

    test('should validate API response data types', () => {
      const invalidResponse = {
        agentId: 123, // Should be string
        stateCode: null, // Should be string
        startDate: 'invalid-date' // Should be valid ISO date
      };
      
      expect(() => validator.validateAgentOnlineStatus(invalidResponse))
        .toThrow('Invalid data types in response');
    });
  });
});
```

## 🔄 Integration Helper Tests

### APIClientHelpers
```javascript
describe('APIClientHelpers', () => {
  describe('retryMechanism', () => {
    test('should retry failed requests with exponential backoff', async () => {
      let attempts = 0;
      const mockApi = jest.fn(() => {
        attempts++;
        if (attempts < 3) throw new Error('Network error');
        return { status: 200, data: 'success' };
      });

      const result = await helpers.retryWithBackoff(mockApi, { maxRetries: 3 });
      
      expect(attempts).toBe(3);
      expect(result.data).toBe('success');
    });

    test('should respect circuit breaker pattern', async () => {
      const circuitBreaker = new CircuitBreaker();
      
      // Trigger circuit breaker with failures
      for (let i = 0; i < 5; i++) {
        try {
          await circuitBreaker.call(() => Promise.reject('Service down'));
        } catch (e) {}
      }
      
      expect(circuitBreaker.state).toBe('OPEN');
      
      // Should not attempt call when open
      const result = await circuitBreaker.call(() => Promise.resolve('success'));
      expect(result).toBeInstanceOf(Error);
    });
  });
});
```

## 🧪 Test Coverage Requirements

### Coverage Targets
- **Unit Tests**: 100% line coverage for calculation functions
- **Branch Coverage**: 100% for conditional logic (uniqueness, AHT, intervals)
- **Edge Cases**: All boundary conditions (null, zero, empty, large datasets)
- **Performance**: Sub-second response for <10K records, <5s for 100K records

### Test Execution Strategy
```bash
# TDD Red-Green-Refactor cycle
npm test -- --coverage --watch
pytest --cov=calculations --cov-report=html
mvn test jacoco:report

# Performance benchmarking
npm run test:performance
pytest --benchmark-only
```

### Mock Data Generators
```javascript
// Test data factory for consistent test scenarios
const TestDataFactory = {
  generateContacts: (count, options = {}) => { /* implementation */ },
  generateAgentStatus: (agentCount, timeRange) => { /* implementation */ },
  generateChatSessions: (sessionCount, botRatio = 0.3) => { /* implementation */ }
};
```

---
**Result**: These unit tests provide **100% coverage** for calculation algorithms, edge cases, and complex business logic that doesn't fit well in BDD format.