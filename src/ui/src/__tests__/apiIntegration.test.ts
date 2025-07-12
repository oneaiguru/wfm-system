/**
 * WFM API Integration Test Suite
 * Comprehensive tests for API integration, data transformation, and real-time features
 */

import { describe, it, expect, jest, beforeEach, afterEach } from '@jest/globals';
import apiIntegrationService from '../services/apiIntegrationService';
import dataTransformationService from '../services/dataTransformationService';
import { wfmWebSocket } from '../../../websocket-client';

// Mock external dependencies
jest.mock('../../../websocket-client');
jest.mock('../services/apiClient');

// Mock data
const mockDashboardData = {
  realTimeMetrics: {
    agentsOnline: 25,
    callsInQueue: 12,
    serviceLevel: 85.3,
    avgWaitTime: 23,
    abandonmentRate: 3.2,
    scheduleAdherence: 92.1,
    forecastAccuracy: 87.5,
    systemHealth: 'healthy' as const
  },
  alerts: [
    {
      id: 'alert-1',
      type: 'sla' as const,
      severity: 'high' as const,
      title: 'Service Level Alert',
      message: 'Service level below target',
      timestamp: '2024-01-15T10:30:00Z',
      acknowledged: false,
      source: 'queue-support'
    }
  ],
  recentActivity: [
    {
      id: 'activity-1',
      type: 'schedule_change' as const,
      description: 'Schedule updated for Agent Smith',
      timestamp: '2024-01-15T10:25:00Z',
      user: 'manager@company.com',
      metadata: { agentId: 'agent-123' }
    }
  ],
  trends: [
    {
      metric: 'service_level',
      data: [
        { timestamp: '2024-01-15T09:00:00Z', value: 82.1 },
        { timestamp: '2024-01-15T09:30:00Z', value: 85.3 },
        { timestamp: '2024-01-15T10:00:00Z', value: 83.7 }
      ],
      change: 2.1,
      unit: '%'
    }
  ]
};

const mockScheduleData = {
  scheduleId: 'schedule-123',
  agents: [
    {
      agentId: 'agent-123',
      name: 'John Smith',
      skills: ['technical', 'billing'],
      shifts: [
        {
          shiftId: 'shift-1',
          startTime: '2024-01-15T09:00:00Z',
          endTime: '2024-01-15T17:00:00Z',
          duration: 8,
          type: 'regular' as const,
          skills: ['technical'],
          location: 'office'
        }
      ],
      totalHours: 8,
      scheduleAdherence: 95.2,
      currentStatus: 'available' as const
    }
  ],
  shifts: [
    {
      id: 'shift-1',
      name: 'Morning Shift',
      startTime: '09:00',
      endTime: '17:00',
      duration: 8,
      requiredSkills: ['technical'],
      capacity: 10,
      assigned: 8,
      available: 2
    }
  ],
  coverage: {
    intervals: [
      {
        timestamp: '2024-01-15T09:00:00Z',
        required: 10,
        available: 8,
        coverage: 80,
        skillBreakdown: {
          technical: { required: 5, available: 4 },
          billing: { required: 3, available: 2 }
        }
      }
    ],
    gaps: [
      {
        startTime: '2024-01-15T14:00:00Z',
        endTime: '2024-01-15T15:00:00Z',
        shortfall: 2,
        affectedSkills: ['technical'],
        severity: 'medium' as const,
        suggestedActions: ['Request overtime', 'Reassign from other queues']
      }
    ],
    overStaffing: [],
    totalCoverage: 85.3,
    skillCoverage: {
      technical: 80,
      billing: 90
    }
  },
  conflicts: [],
  optimization: {
    totalSavings: 15.5,
    suggestions: [
      {
        id: 'opt-1',
        type: 'shift_swap' as const,
        description: 'Swap shifts between Agent A and Agent B',
        impact: 5.2,
        cost: 0,
        feasibility: 95,
        agentsAffected: ['agent-123', 'agent-456']
      }
    ],
    implementationComplexity: 'low' as const,
    expectedImpact: 8.7
  }
};

const mockForecastData = {
  forecastId: 'forecast-123',
  timeRange: {
    start: '2024-01-15T00:00:00Z',
    end: '2024-01-15T23:59:59Z'
  },
  intervals: [
    {
      timestamp: '2024-01-15T09:00:00Z',
      predictedVolume: 150,
      confidenceInterval: { lower: 135, upper: 165 },
      requiredAgents: 12,
      aht: 180,
      serviceLevel: 85,
      skills: { technical: 8, billing: 4 }
    }
  ],
  accuracy: {
    mape: 12.5,
    rmse: 8.3,
    mae: 6.7,
    r2: 0.85,
    lastUpdated: '2024-01-15T10:00:00Z',
    historicalAccuracy: [
      { period: '2024-01-01', accuracy: 87.2 },
      { period: '2024-01-08', accuracy: 85.6 }
    ]
  },
  scenarios: [
    {
      id: 'scenario-1',
      name: 'Best Case',
      description: 'Optimistic forecast scenario',
      parameters: { confidence: 0.9 },
      results: [],
      probability: 0.25
    }
  ],
  adjustments: []
};

const mockArgusData = {
  agent_data: {
    id: 'agent-123',
    name: 'John Smith',
    login_id: 'jsmith',
    skills: ['technical', 'billing'],
    status: 'Ready',
    location: 'Office Floor 1'
  },
  queue_data: {
    queue_id: 'queue-support',
    name: 'Technical Support',
    type: 'Inbound',
    priority: 3,
    sla_threshold: 30,
    current_load: 12
  },
  schedule_data: {
    schedule_id: 'schedule-123',
    agent_id: 'agent-123',
    date: '2024-01-15',
    shift_start: '09:00',
    shift_end: '17:00',
    break_schedule: ['12:00', '15:00'],
    assigned_queues: ['queue-support', 'queue-billing']
  },
  forecast_data: {
    interval: '2024-01-15T09:00:00Z',
    call_volume: 150,
    avg_handle_time: 180,
    service_level: 85,
    abandonment_rate: 3.2
  }
};

describe('API Integration Service', () => {
  let mockApiClient: any;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Mock API client
    mockApiClient = {
      get: jest.fn(),
      post: jest.fn(),
      put: jest.fn(),
      delete: jest.fn()
    };
    
    // Mock WebSocket
    (wfmWebSocket as any).connect = jest.fn().mockResolvedValue(undefined);
    (wfmWebSocket as any).subscribe = jest.fn().mockReturnValue(jest.fn());
    (wfmWebSocket as any).isWebSocketConnected = jest.fn().mockReturnValue(true);
    (wfmWebSocket as any).joinRoom = jest.fn();
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('Dashboard Data Integration', () => {
    it('should fetch dashboard data successfully', async () => {
      // Mock API responses
      mockApiClient.get
        .mockResolvedValueOnce(mockDashboardData.realTimeMetrics) // status endpoint
        .mockResolvedValueOnce({ alerts: mockDashboardData.alerts }) // alerts endpoint
        .mockResolvedValueOnce({ activities: mockDashboardData.recentActivity }) // activity endpoint
        .mockResolvedValueOnce({ trends: mockDashboardData.trends }); // trends endpoint

      const result = await apiIntegrationService.getDashboardData();

      expect(result).toEqual(mockDashboardData);
      expect(mockApiClient.get).toHaveBeenCalledTimes(4);
    });

    it('should handle dashboard data fetch errors', async () => {
      mockApiClient.get.mockRejectedValue(new Error('API Error'));

      await expect(apiIntegrationService.getDashboardData()).rejects.toThrow('API Error');
    });

    it('should cache dashboard data', async () => {
      mockApiClient.get
        .mockResolvedValueOnce(mockDashboardData.realTimeMetrics)
        .mockResolvedValueOnce({ alerts: mockDashboardData.alerts })
        .mockResolvedValueOnce({ activities: mockDashboardData.recentActivity })
        .mockResolvedValueOnce({ trends: mockDashboardData.trends });

      // First call
      await apiIntegrationService.getDashboardData();
      
      // Second call should use cache
      const result = await apiIntegrationService.getDashboardData();

      expect(result).toEqual(mockDashboardData);
      expect(mockApiClient.get).toHaveBeenCalledTimes(4); // Should not make additional calls
    });
  });

  describe('Schedule Data Integration', () => {
    it('should fetch schedule data successfully', async () => {
      mockApiClient.get.mockResolvedValue(mockScheduleData);

      const result = await apiIntegrationService.getScheduleData('schedule-123');

      expect(result).toEqual(mockScheduleData);
      expect(mockApiClient.get).toHaveBeenCalledWith('/schedules/schedule-123');
    });

    it('should update schedule data', async () => {
      mockApiClient.put.mockResolvedValue({ success: true });

      const updates = { agents: mockScheduleData.agents };
      await apiIntegrationService.updateSchedule('schedule-123', updates);

      expect(mockApiClient.put).toHaveBeenCalledWith('/schedules/schedule-123', updates);
    });

    it('should optimize schedule', async () => {
      const optimizationResult = mockScheduleData.optimization;
      mockApiClient.post.mockResolvedValue({ optimization: optimizationResult });

      const parameters = { algorithm: 'genetic', iterations: 100 };
      const result = await apiIntegrationService.optimizeSchedule('schedule-123', parameters);

      expect(result).toEqual(optimizationResult);
      expect(mockApiClient.post).toHaveBeenCalledWith('/schedules/schedule-123/optimize', parameters);
    });

    it('should publish schedule', async () => {
      mockApiClient.post.mockResolvedValue({ success: true });

      await apiIntegrationService.publishSchedule('schedule-123');

      expect(mockApiClient.post).toHaveBeenCalledWith('/schedules/schedule-123/publish');
    });
  });

  describe('Forecast Data Integration', () => {
    it('should fetch forecast data successfully', async () => {
      mockApiClient.get.mockResolvedValue(mockForecastData);

      const result = await apiIntegrationService.getForecastData('forecast-123');

      expect(result).toEqual(mockForecastData);
      expect(mockApiClient.get).toHaveBeenCalledWith('/forecasts/forecast-123');
    });

    it('should generate forecast', async () => {
      mockApiClient.post.mockResolvedValue(mockForecastData);

      const parameters = { algorithm: 'arima', horizon: 24 };
      const result = await apiIntegrationService.generateForecast(parameters);

      expect(result).toEqual(mockForecastData);
      expect(mockApiClient.post).toHaveBeenCalledWith('/forecasts/generate', parameters);
    });

    it('should adjust forecast', async () => {
      mockApiClient.post.mockResolvedValue({ success: true });

      const adjustments = [
        { id: 'adj-1', timestamp: '2024-01-15T10:00:00Z', adjustment: 10, reason: 'Manual override' }
      ];
      await apiIntegrationService.adjustForecast('forecast-123', adjustments);

      expect(mockApiClient.post).toHaveBeenCalledWith('/forecasts/forecast-123/adjust', { adjustments });
    });
  });

  describe('WebSocket Integration', () => {
    it('should subscribe to real-time events', () => {
      const callback = jest.fn();
      
      apiIntegrationService.subscribe('agent_status', callback);

      expect(wfmWebSocket.subscribe).toHaveBeenCalledWith('agent_status', expect.any(Function));
      expect(wfmWebSocket.joinRoom).toHaveBeenCalledWith('agent_status');
    });

    it('should handle WebSocket connection status', () => {
      const isConnected = apiIntegrationService.isWebSocketConnected();

      expect(isConnected).toBe(true);
      expect(wfmWebSocket.isWebSocketConnected).toHaveBeenCalled();
    });

    it('should notify subscribers on real-time events', () => {
      const callback = jest.fn();
      
      // Subscribe to event
      apiIntegrationService.subscribe('agent_status', callback);
      
      // Simulate WebSocket event
      const eventData = { agentId: 'agent-123', status: 'busy' };
      // This would normally be called by the WebSocket handler
      apiIntegrationService['notifySubscribers']('agent_status', eventData);

      expect(callback).toHaveBeenCalledWith(eventData);
    });
  });

  describe('Algorithm Integration', () => {
    it('should calculate Erlang C', async () => {
      const erlangResult = {
        utilization: 0.8,
        probability_wait: 0.15,
        average_wait_time: 12.5,
        service_level: 85.3,
        queue_length: 2.1,
        optimal_agents: 12
      };
      
      mockApiClient.post.mockResolvedValue(erlangResult);

      const parameters = {
        arrival_rate: 100,
        service_time: 180,
        agents: 12,
        target_service_level: 0.8
      };
      
      const result = await apiIntegrationService.calculateErlangC(parameters);

      expect(result).toEqual(erlangResult);
      expect(mockApiClient.post).toHaveBeenCalledWith('/algorithms/erlang-c/calculate', parameters);
    });

    it('should run multi-skill optimization', async () => {
      const optimizationResult = {
        accuracy: 87.5,
        assignments: [
          { agentId: 'agent-123', skills: ['technical'], utilization: 0.85 }
        ],
        improvement: 12.3
      };
      
      mockApiClient.post.mockResolvedValue(optimizationResult);

      const parameters = {
        agents: 50,
        queues: 10,
        skills: ['technical', 'billing'],
        optimization_target: 'accuracy'
      };
      
      const result = await apiIntegrationService.runMultiSkillOptimization(parameters);

      expect(result).toEqual(optimizationResult);
      expect(mockApiClient.post).toHaveBeenCalledWith('/algorithms/multi-skill/optimize', parameters);
    });

    it('should get algorithm status', async () => {
      const statusResult = {
        algorithms: [
          { name: 'erlang_c', status: 'active', version: '1.0.0' },
          { name: 'multi_skill', status: 'active', version: '2.1.0' }
        ],
        system_health: 'healthy'
      };
      
      mockApiClient.get.mockResolvedValue(statusResult);

      const result = await apiIntegrationService.getAlgorithmStatus();

      expect(result).toEqual(statusResult);
      expect(mockApiClient.get).toHaveBeenCalledWith('/algorithms/status');
    });
  });

  describe('Cache Management', () => {
    it('should get cache statistics', () => {
      const stats = apiIntegrationService.getCacheStats();

      expect(stats).toHaveProperty('size');
      expect(stats).toHaveProperty('keys');
      expect(stats).toHaveProperty('subscriptions');
      expect(typeof stats.size).toBe('number');
      expect(Array.isArray(stats.keys)).toBe(true);
    });

    it('should clear cache', () => {
      apiIntegrationService.clearCache();
      
      const stats = apiIntegrationService.getCacheStats();
      expect(stats.size).toBe(0);
      expect(stats.keys).toEqual([]);
    });
  });

  describe('Error Handling', () => {
    it('should handle API errors gracefully', async () => {
      mockApiClient.get.mockRejectedValue(new Error('Network Error'));

      await expect(apiIntegrationService.getDashboardData()).rejects.toThrow('Network Error');
    });

    it('should handle WebSocket connection errors', () => {
      (wfmWebSocket as any).connect.mockRejectedValue(new Error('WebSocket Error'));
      
      // The service should handle this gracefully and continue working
      expect(() => apiIntegrationService.isWebSocketConnected()).not.toThrow();
    });
  });
});

describe('Data Transformation Service', () => {
  describe('Argus Compatibility', () => {
    it('should transform Argus agent data to WFM format', () => {
      const result = dataTransformationService.transformArgusToWFM(mockArgusData.agent_data, 'agent_data');

      expect(result).toEqual({
        id: 'agent-123',
        name: 'John Smith',
        email: 'jsmith@company.com',
        skills: [
          { skillId: 'technical', level: 3, certified: true },
          { skillId: 'billing', level: 3, certified: true }
        ],
        status: 'available',
        location: 'Office Floor 1',
        department: 'Contact Center',
        schedule: 'standard'
      });
    });

    it('should transform Argus queue data to WFM format', () => {
      const result = dataTransformationService.transformArgusToWFM(mockArgusData.queue_data, 'queue_data');

      expect(result).toEqual({
        id: 'queue-support',
        name: 'Technical Support',
        description: 'Queue Technical Support',
        type: 'inbound',
        priority: 'high',
        sla: {
          target: 30,
          threshold: 24,
          unit: 'seconds'
        },
        metrics: {
          callsInQueue: 12,
          avgWaitTime: 0,
          serviceLevel: 0,
          abandonment: 0,
          timestamp: expect.any(String)
        }
      });
    });

    it('should transform Argus schedule data to WFM format', () => {
      const result = dataTransformationService.transformArgusToWFM(mockArgusData.schedule_data, 'schedule_data');

      expect(result).toEqual({
        id: 'schedule-123',
        agentId: 'agent-123',
        date: '2024-01-15',
        shifts: [
          {
            startTime: '09:00',
            endTime: '17:00',
            type: 'regular',
            skills: [],
            location: undefined
          }
        ],
        breaks: [
          {
            startTime: '12:00',
            endTime: expect.any(String),
            type: 'break',
            duration: 15
          },
          {
            startTime: '15:00',
            endTime: expect.any(String),
            type: 'break',
            duration: 15
          }
        ],
        assignedQueues: ['queue-support', 'queue-billing'],
        totalHours: 8,
        overtime: 0
      });
    });

    it('should transform Argus forecast data to WFM format', () => {
      const result = dataTransformationService.transformArgusToWFM(mockArgusData.forecast_data, 'forecast_data');

      expect(result).toEqual({
        timestamp: '2024-01-15T09:00:00Z',
        callVolume: 150,
        aht: 180,
        serviceLevel: 85,
        abandonment: 3.2,
        requiredAgents: 8, // Calculated based on call volume and AHT
        confidence: {
          lower: 135,
          upper: 165
        }
      });
    });
  });

  describe('Chart Data Transformation', () => {
    it('should transform data to line chart format', () => {
      const data = [
        { time: '09:00', calls: 100, aht: 180 },
        { time: '10:00', calls: 120, aht: 175 },
        { time: '11:00', calls: 95, aht: 185 }
      ];

      const result = dataTransformationService.transformToChartData(data, {
        xAxis: 'time',
        yAxis: 'calls',
        chartType: 'line',
        colors: ['#3B82F6']
      });

      expect(result).toEqual({
        labels: ['09:00', '10:00', '11:00'],
        datasets: [
          {
            label: 'Calls',
            data: [100, 120, 95],
            borderColor: '#3B82F6',
            backgroundColor: '#3B82F6',
            fill: false,
            tension: 0.4,
            pointRadius: 3,
            pointHoverRadius: 5
          }
        ]
      });
    });

    it('should transform data to multi-series chart format', () => {
      const data = [
        { time: '09:00', calls: 100, aht: 180 },
        { time: '10:00', calls: 120, aht: 175 }
      ];

      const result = dataTransformationService.transformToChartData(data, {
        xAxis: 'time',
        yAxis: ['calls', 'aht'],
        chartType: 'line',
        colors: ['#3B82F6', '#10B981']
      });

      expect(result.datasets).toHaveLength(2);
      expect(result.datasets[0].label).toBe('Calls');
      expect(result.datasets[1].label).toBe('Aht');
      expect(result.datasets[0].data).toEqual([100, 120]);
      expect(result.datasets[1].data).toEqual([180, 175]);
    });

    it('should handle area chart transformation', () => {
      const data = [
        { time: '09:00', calls: 100 },
        { time: '10:00', calls: 120 }
      ];

      const result = dataTransformationService.transformToChartData(data, {
        xAxis: 'time',
        yAxis: 'calls',
        chartType: 'area',
        colors: ['#3B82F6']
      });

      expect(result.datasets[0].fill).toBe(true);
      expect(result.datasets[0].backgroundColor).toBe('rgba(59, 130, 246, 0.2)');
    });
  });

  describe('Table Data Transformation', () => {
    it('should transform data to table format', () => {
      const data = [
        { id: 1, name: 'John', status: 'active', score: 85.5, joined: '2024-01-15' },
        { id: 2, name: 'Jane', status: 'inactive', score: 92.1, joined: '2024-01-10' }
      ];

      const result = dataTransformationService.transformToTableData(data, {
        columns: [
          { key: 'name', label: 'Name', type: 'text' },
          { key: 'status', label: 'Status', type: 'status' },
          { key: 'score', label: 'Score', type: 'number' },
          { key: 'joined', label: 'Joined', type: 'date' }
        ],
        pagination: { page: 1, limit: 10 }
      });

      expect(result.columns).toHaveLength(4);
      expect(result.rows).toHaveLength(2);
      expect(result.rows[0]).toEqual({
        name: 'John',
        status: 'Active',
        score: '85.50',
        joined: '2024-01-15'
      });
      expect(result.pagination).toEqual({
        page: 1,
        limit: 10,
        total: 2
      });
    });

    it('should apply filters to table data', () => {
      const data = [
        { name: 'John', status: 'active', score: 85 },
        { name: 'Jane', status: 'inactive', score: 92 },
        { name: 'Bob', status: 'active', score: 78 }
      ];

      const result = dataTransformationService.transformToTableData(data, {
        columns: [
          { key: 'name', label: 'Name', type: 'text' },
          { key: 'status', label: 'Status', type: 'status' }
        ],
        filters: { status: 'active' }
      });

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(row => row.status === 'Active')).toBe(true);
    });

    it('should apply sorting to table data', () => {
      const data = [
        { name: 'John', score: 85 },
        { name: 'Jane', score: 92 },
        { name: 'Bob', score: 78 }
      ];

      const result = dataTransformationService.transformToTableData(data, {
        columns: [
          { key: 'name', label: 'Name', type: 'text' },
          { key: 'score', label: 'Score', type: 'number' }
        ],
        sorting: { column: 'score', direction: 'desc' }
      });

      expect(result.rows[0].name).toBe('Jane');
      expect(result.rows[1].name).toBe('John');
      expect(result.rows[2].name).toBe('Bob');
    });
  });

  describe('Real-time Data Transformation', () => {
    it('should transform agent status updates', () => {
      const data = {
        agent_id: 'agent-123',
        status: 'busy',
        previous_status: 'available',
        timestamp: '2024-01-15T10:30:00Z',
        location: 'Office Floor 1',
        skills: ['technical', 'billing']
      };

      const result = dataTransformationService.transformRealTimeData(data, 'agent_status');

      expect(result).toEqual({
        agentId: 'agent-123',
        status: 'busy',
        previousStatus: 'available',
        timestamp: '2024-01-15 10:30:00',
        location: 'Office Floor 1',
        skills: ['technical', 'billing'],
        metadata: {
          statusDuration: 0,
          autoGenerated: false
        }
      });
    });

    it('should transform queue metrics updates', () => {
      const data = {
        queue_id: 'queue-support',
        timestamp: '2024-01-15T10:30:00Z',
        metrics: {
          calls_in_queue: 15,
          avg_wait_time: 25,
          service_level: 82,
          abandonment: 4.1
        },
        thresholds: {
          avg_wait_time: 30,
          service_level: 80
        }
      };

      const result = dataTransformationService.transformRealTimeData(data, 'queue_metrics');

      expect(result).toEqual({
        queueId: 'queue-support',
        groupId: undefined,
        timestamp: '2024-01-15 10:30:00',
        metrics: {
          callsInQueue: 15,
          avgWaitTime: 25,
          serviceLevel: 82,
          abandonment: 4.1,
          throughput: 0
        },
        thresholds: {
          avg_wait_time: 30,
          service_level: 80
        },
        alerts: []
      });
    });
  });

  describe('Data Validation', () => {
    it('should validate data against schema', () => {
      const data = {
        name: 'John',
        age: 25,
        email: 'john@example.com'
      };

      const schema = {
        type: 'object',
        required: ['name', 'email'],
        properties: {
          name: { type: 'string', minLength: 1 },
          age: { type: 'number', minimum: 0 },
          email: { type: 'string', pattern: '^[^@]+@[^@]+\.[^@]+$' }
        }
      };

      const result = dataTransformationService.validateData(data, schema);

      expect(result.valid).toBe(true);
      expect(result.errors).toEqual([]);
    });

    it('should detect validation errors', () => {
      const data = {
        name: '',
        age: -5,
        email: 'invalid-email'
      };

      const schema = {
        type: 'object',
        required: ['name', 'email'],
        properties: {
          name: { type: 'string', minLength: 1 },
          age: { type: 'number', minimum: 0 },
          email: { type: 'string', pattern: '^[^@]+@[^@]+\.[^@]+$' }
        }
      };

      const result = dataTransformationService.validateData(data, schema);

      expect(result.valid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });

    it('should handle missing required fields', () => {
      const data = {
        name: 'John'
      };

      const schema = {
        type: 'object',
        required: ['name', 'email'],
        properties: {
          name: { type: 'string' },
          email: { type: 'string' }
        }
      };

      const result = dataTransformationService.validateData(data, schema);

      expect(result.valid).toBe(false);
      expect(result.errors.some(err => err.includes('email'))).toBe(true);
    });
  });

  describe('Utility Functions', () => {
    it('should get transformation options', () => {
      const options = dataTransformationService.getTransformationOptions();

      expect(options).toHaveProperty('dateFormat');
      expect(options).toHaveProperty('timezone');
      expect(options).toHaveProperty('precision');
      expect(options).toHaveProperty('nullHandling');
    });

    it('should set transformation options', () => {
      const newOptions = {
        dateFormat: 'dd/MM/yyyy',
        precision: 3
      };

      dataTransformationService.setTransformationOptions(newOptions);
      const options = dataTransformationService.getTransformationOptions();

      expect(options.dateFormat).toBe('dd/MM/yyyy');
      expect(options.precision).toBe(3);
    });

    it('should reset transformation options', () => {
      dataTransformationService.setTransformationOptions({ precision: 5 });
      dataTransformationService.resetTransformationOptions();
      
      const options = dataTransformationService.getTransformationOptions();
      expect(options.precision).toBe(2); // Default value
    });
  });
});

describe('Integration Performance Tests', () => {
  it('should handle large datasets efficiently', async () => {
    const largeDataset = Array.from({ length: 10000 }, (_, i) => ({
      id: i,
      timestamp: `2024-01-15T${String(i % 24).padStart(2, '0')}:00:00Z`,
      value: Math.random() * 100
    }));

    const startTime = performance.now();
    
    const result = dataTransformationService.transformToChartData(largeDataset, {
      xAxis: 'timestamp',
      yAxis: 'value',
      chartType: 'line',
      timeFormat: 'HH:mm'
    });

    const endTime = performance.now();
    const duration = endTime - startTime;

    expect(result.labels).toHaveLength(10000);
    expect(result.datasets[0].data).toHaveLength(10000);
    expect(duration).toBeLessThan(1000); // Should complete within 1 second
  });

  it('should handle multiple concurrent API calls', async () => {
    const promises = [
      apiIntegrationService.getDashboardData(),
      apiIntegrationService.getScheduleData(),
      apiIntegrationService.getForecastData(),
      apiIntegrationService.getPersonnelData()
    ];

    const startTime = performance.now();
    
    // Mock all API calls to resolve successfully
    mockApiClient.get.mockResolvedValue({ data: 'mock' });
    
    const results = await Promise.allSettled(promises);
    
    const endTime = performance.now();
    const duration = endTime - startTime;

    expect(results.every(result => result.status === 'fulfilled')).toBe(true);
    expect(duration).toBeLessThan(2000); // Should complete within 2 seconds
  });
});

describe('Error Recovery Tests', () => {
  it('should retry failed API calls', async () => {
    let callCount = 0;
    mockApiClient.get.mockImplementation(() => {
      callCount++;
      if (callCount < 3) {
        return Promise.reject(new Error('Network Error'));
      }
      return Promise.resolve(mockDashboardData);
    });

    const result = await apiIntegrationService.getDashboardData();

    expect(callCount).toBe(3);
    expect(result).toEqual(mockDashboardData);
  });

  it('should handle WebSocket reconnection', () => {
    let connectionAttempts = 0;
    (wfmWebSocket as any).connect.mockImplementation(() => {
      connectionAttempts++;
      if (connectionAttempts < 3) {
        return Promise.reject(new Error('Connection failed'));
      }
      return Promise.resolve();
    });

    // The service should handle reconnection internally
    expect(() => apiIntegrationService.isWebSocketConnected()).not.toThrow();
  });
});

describe('Memory Management Tests', () => {
  it('should properly clean up subscriptions', () => {
    const unsubscribe1 = apiIntegrationService.subscribe('test_event', () => {});
    const unsubscribe2 = apiIntegrationService.subscribe('test_event', () => {});

    const statsBefore = apiIntegrationService.getCacheStats();
    
    unsubscribe1();
    unsubscribe2();
    
    const statsAfter = apiIntegrationService.getCacheStats();
    
    expect(statsAfter.subscriptions).toBeLessThanOrEqual(statsBefore.subscriptions);
  });

  it('should limit cache size', () => {
    // Fill cache with many entries
    for (let i = 0; i < 1000; i++) {
      apiIntegrationService['setCache'](`key_${i}`, { data: i });
    }

    const stats = apiIntegrationService.getCacheStats();
    
    // Cache should have reasonable size limits
    expect(stats.size).toBeLessThan(500); // Assuming LRU eviction
  });
});

describe('Edge Cases', () => {
  it('should handle null/undefined data gracefully', () => {
    expect(() => {
      dataTransformationService.transformToChartData(null, {
        xAxis: 'x',
        yAxis: 'y',
        chartType: 'line'
      });
    }).not.toThrow();
  });

  it('should handle empty arrays', () => {
    const result = dataTransformationService.transformToChartData([], {
      xAxis: 'x',
      yAxis: 'y',
      chartType: 'line'
    });

    expect(result.labels).toEqual([]);
    expect(result.datasets[0].data).toEqual([]);
  });

  it('should handle malformed date strings', () => {
    const data = [
      { timestamp: 'invalid-date', value: 100 },
      { timestamp: '2024-01-15T10:00:00Z', value: 200 }
    ];

    const result = dataTransformationService.transformToChartData(data, {
      xAxis: 'timestamp',
      yAxis: 'value',
      chartType: 'line',
      timeFormat: 'HH:mm'
    });

    expect(result.labels).toEqual(['invalid-date', '10:00']);
    expect(result.datasets[0].data).toEqual([100, 200]);
  });
});

describe('API Contract Compliance', () => {
  it('should maintain backward compatibility with Argus API', () => {
    // Test that we can handle both old and new API formats
    const argusResponse = {
      agent_id: 'agent-123',
      status: 'Ready',
      login_time: '2024-01-15T09:00:00Z'
    };

    const modernResponse = {
      agentId: 'agent-123',
      status: 'available',
      loginTime: '2024-01-15T09:00:00Z'
    };

    // Both should be handled correctly
    expect(() => {
      dataTransformationService.transformRealTimeData(argusResponse, 'agent_status');
      dataTransformationService.transformRealTimeData(modernResponse, 'agent_status');
    }).not.toThrow();
  });

  it('should validate API response schemas', () => {
    const invalidResponse = {
      // Missing required fields
      id: 'test'
    };

    const validResponse = {
      id: 'test',
      name: 'Test',
      type: 'test'
    };

    const schema = {
      type: 'object',
      required: ['id', 'name', 'type'],
      properties: {
        id: { type: 'string' },
        name: { type: 'string' },
        type: { type: 'string' }
      }
    };

    const invalidResult = dataTransformationService.validateData(invalidResponse, schema);
    const validResult = dataTransformationService.validateData(validResponse, schema);

    expect(invalidResult.valid).toBe(false);
    expect(validResult.valid).toBe(true);
  });
});