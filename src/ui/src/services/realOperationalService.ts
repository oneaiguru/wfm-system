/**
 * REAL Operational Service - Real-time monitoring and operational control API
 * NO MOCK DATA - connects to real INTEGRATION-OPUS endpoints
 * Following proven realWorkRuleService.ts pattern
 */

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface OperationalMetrics {
  serviceLevel: {
    current: number;
    target: number;
    trend: 'up' | 'down' | 'stable';
    status: 'green' | 'yellow' | 'red';
  };
  averageHandleTime: {
    current: number;
    target: number;
    trend: 'up' | 'down' | 'stable';
    status: 'green' | 'yellow' | 'red';
  };
  queueVolume: {
    current: number;
    capacity: number;
    trend: 'up' | 'down' | 'stable';
    status: 'green' | 'yellow' | 'red';
  };
  staffingLevel: {
    current: number;
    required: number;
    trend: 'up' | 'down' | 'stable';
    status: 'green' | 'yellow' | 'red';
  };
  responseTime: {
    current: number;
    target: number;
    trend: 'up' | 'down' | 'stable';
    status: 'green' | 'yellow' | 'red';
  };
  customerSatisfaction: {
    current: number;
    target: number;
    trend: 'up' | 'down' | 'stable';
    status: 'green' | 'yellow' | 'red';
  };
  timestamp: string;
}

export interface AgentStatus {
  id: string;
  name: string;
  state: 'available' | 'busy' | 'break' | 'offline' | 'after_call_work';
  currentTask: string | null;
  currentTaskDuration: number;
  skills: string[];
  queue: string;
  lastActivity: string;
  performance: {
    callsHandled: number;
    avgHandleTime: number;
    customerRating: number;
  };
}

export interface QueueMetrics {
  queueId: string;
  queueName: string;
  waitingCalls: number;
  longestWait: number;
  avgWaitTime: number;
  abandonRate: number;
  serviceLevel: number;
  agentsLoggedIn: number;
  agentsAvailable: number;
  callsHandled: number;
  callsAbandoned: number;
  status: 'normal' | 'warning' | 'critical';
}

export interface AlertItem {
  id: string;
  type: 'threshold' | 'predictive' | 'system' | 'performance';
  severity: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  message: string;
  timestamp: string;
  acknowledged: boolean;
  acknowledgedBy?: string;
  acknowledgedAt?: string;
  resolvedAt?: string;
  source: string;
  affectedQueues: string[];
  recommendedAction?: string;
}

export interface ThresholdConfiguration {
  id: string;
  metric: string;
  name: string;
  warningThreshold: number;
  criticalThreshold: number;
  enabled: boolean;
  operator: 'greater_than' | 'less_than' | 'equals';
  timeWindow: number; // minutes
  consecutiveBreaches: number;
}

export interface DrillDownData {
  metricId: string;
  timeRange: string;
  granularity: '5min' | '15min' | '1hour' | '1day';
  data: {
    timestamp: string;
    value: number;
    target?: number;
    status: 'green' | 'yellow' | 'red';
  }[];
  summary: {
    min: number;
    max: number;
    avg: number;
    trend: 'up' | 'down' | 'stable';
    breaches: number;
  };
}

export interface ForecastData {
  metric: string;
  timeRange: string;
  predictions: {
    timestamp: string;
    predicted: number;
    confidence: number;
    upperBound: number;
    lowerBound: number;
  }[];
  accuracy: number;
}

export interface RealTimeUpdate {
  type: 'metrics' | 'alert' | 'agent_status' | 'queue_status';
  data: any;
  timestamp: string;
}

const API_BASE_URL = 'http://localhost:8000/api/v1';

class RealOperationalService {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;
  private updateCallbacks: ((update: RealTimeUpdate) => void)[] = [];
  
  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
          ...options.headers,
        },
        ...options,
      });

      console.log(`[REAL API] Response status: ${response.status}`);

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[REAL API] Error response: ${errorText}`);
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      console.log(`[REAL API] Success response:`, data);
      
      return {
        success: true,
        data: data as T
      };

    } catch (error) {
      console.error(`[REAL API] Request failed:`, error);
      
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  private getAuthToken(): string {
    const token = localStorage.getItem('authToken');
    if (!token) {
      throw new Error('No authentication token found');
    }
    return token;
  }

  // Real-time metrics
  async getCurrentMetrics(): Promise<ApiResponse<OperationalMetrics>> {
    console.log('[REAL API] Fetching current operational metrics...');
    
    return this.makeRequest<OperationalMetrics>('/operational/metrics/current');
  }

  async getMetricsHistory(timeRange: string): Promise<ApiResponse<OperationalMetrics[]>> {
    console.log(`[REAL API] Fetching metrics history for ${timeRange}...`);
    
    return this.makeRequest<OperationalMetrics[]>(`/operational/metrics/history?range=${timeRange}`);
  }

  // Agent management
  async getAgentStatuses(): Promise<ApiResponse<AgentStatus[]>> {
    console.log('[REAL API] Fetching agent statuses...');
    
    return this.makeRequest<AgentStatus[]>('/operational/agents/status');
  }

  async getAgentStatus(agentId: string): Promise<ApiResponse<AgentStatus>> {
    console.log(`[REAL API] Fetching agent status for ${agentId}...`);
    
    return this.makeRequest<AgentStatus>(`/operational/agents/${agentId}/status`);
  }

  async updateAgentState(agentId: string, state: string, reason?: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Updating agent ${agentId} state to ${state}...`);
    
    return this.makeRequest<{ success: boolean }>(`/operational/agents/${agentId}/state`, {
      method: 'PUT',
      body: JSON.stringify({ state, reason })
    });
  }

  // Queue management
  async getQueueMetrics(): Promise<ApiResponse<QueueMetrics[]>> {
    console.log('[REAL API] Fetching queue metrics...');
    
    return this.makeRequest<QueueMetrics[]>('/operational/queues/metrics');
  }

  async getQueueMetrics_Single(queueId: string): Promise<ApiResponse<QueueMetrics>> {
    console.log(`[REAL API] Fetching metrics for queue ${queueId}...`);
    
    return this.makeRequest<QueueMetrics>(`/operational/queues/${queueId}/metrics`);
  }

  async getQueueAgents(queueId: string): Promise<ApiResponse<AgentStatus[]>> {
    console.log(`[REAL API] Fetching agents for queue ${queueId}...`);
    
    return this.makeRequest<AgentStatus[]>(`/operational/queues/${queueId}/agents`);
  }

  // Alerts and thresholds
  async getActiveAlerts(): Promise<ApiResponse<AlertItem[]>> {
    console.log('[REAL API] Fetching active alerts...');
    
    return this.makeRequest<AlertItem[]>('/operational/alerts/active');
  }

  async getAlertHistory(timeRange: string): Promise<ApiResponse<AlertItem[]>> {
    console.log(`[REAL API] Fetching alert history for ${timeRange}...`);
    
    return this.makeRequest<AlertItem[]>(`/operational/alerts/history?range=${timeRange}`);
  }

  async acknowledgeAlert(alertId: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Acknowledging alert ${alertId}...`);
    
    return this.makeRequest<{ success: boolean }>(`/operational/alerts/${alertId}/acknowledge`, {
      method: 'POST'
    });
  }

  async resolveAlert(alertId: string, resolution: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Resolving alert ${alertId}...`);
    
    return this.makeRequest<{ success: boolean }>(`/operational/alerts/${alertId}/resolve`, {
      method: 'POST',
      body: JSON.stringify({ resolution })
    });
  }

  // Threshold configuration
  async getThresholds(): Promise<ApiResponse<ThresholdConfiguration[]>> {
    console.log('[REAL API] Fetching threshold configurations...');
    
    return this.makeRequest<ThresholdConfiguration[]>('/operational/thresholds');
  }

  async updateThreshold(thresholdId: string, config: Partial<ThresholdConfiguration>): Promise<ApiResponse<ThresholdConfiguration>> {
    console.log(`[REAL API] Updating threshold ${thresholdId}...`);
    
    return this.makeRequest<ThresholdConfiguration>(`/operational/thresholds/${thresholdId}`, {
      method: 'PUT',
      body: JSON.stringify(config)
    });
  }

  // Drill-down analytics
  async getDrillDownData(metricId: string, timeRange: string, granularity: string): Promise<ApiResponse<DrillDownData>> {
    console.log(`[REAL API] Fetching drill-down data for ${metricId}...`);
    
    return this.makeRequest<DrillDownData>(`/operational/metrics/${metricId}/drill-down`, {
      method: 'POST',
      body: JSON.stringify({ timeRange, granularity })
    });
  }

  // Forecasting
  async getForecast(metric: string, timeRange: string): Promise<ApiResponse<ForecastData>> {
    console.log(`[REAL API] Fetching forecast for ${metric}...`);
    
    return this.makeRequest<ForecastData>(`/operational/forecasting/${metric}`, {
      method: 'POST',
      body: JSON.stringify({ timeRange })
    });
  }

  // Real-time WebSocket connection
  connectRealTimeUpdates(): () => void {
    if (this.ws) {
      this.ws.close();
    }

    const wsUrl = `ws://localhost:8000/ws/operational`;
    console.log(`[REAL API] Connecting to WebSocket: ${wsUrl}`);

    this.ws = new WebSocket(wsUrl);

    this.ws.onopen = () => {
      console.log('[REAL API] WebSocket connected');
      this.reconnectAttempts = 0;
      
      // Send authentication
      this.ws?.send(JSON.stringify({
        type: 'auth',
        token: this.getAuthToken()
      }));
    };

    this.ws.onmessage = (event) => {
      try {
        const update: RealTimeUpdate = JSON.parse(event.data);
        console.log('[REAL API] Received real-time update:', update);
        
        this.updateCallbacks.forEach(callback => callback(update));
      } catch (error) {
        console.error('[REAL API] Failed to parse WebSocket message:', error);
      }
    };

    this.ws.onclose = () => {
      console.log('[REAL API] WebSocket disconnected');
      this.attemptReconnect();
    };

    this.ws.onerror = (error) => {
      console.error('[REAL API] WebSocket error:', error);
    };

    // Return cleanup function
    return () => {
      if (this.ws) {
        this.ws.close();
        this.ws = null;
      }
    };
  }

  private attemptReconnect(): void {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.log(`[REAL API] Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);
      
      setTimeout(() => {
        this.connectRealTimeUpdates();
      }, this.reconnectDelay * this.reconnectAttempts);
    }
  }

  subscribeToUpdates(callback: (update: RealTimeUpdate) => void): () => void {
    this.updateCallbacks.push(callback);
    
    return () => {
      this.updateCallbacks = this.updateCallbacks.filter(cb => cb !== callback);
    };
  }

  // Dashboard actions
  async refreshDashboard(): Promise<ApiResponse<{ success: boolean }>> {
    console.log('[REAL API] Refreshing dashboard data...');
    
    return this.makeRequest<{ success: boolean }>('/operational/dashboard/refresh', {
      method: 'POST'
    });
  }

  async exportMetrics(format: 'csv' | 'excel' | 'json', timeRange: string): Promise<ApiResponse<{ url: string; filename: string }>> {
    console.log(`[REAL API] Exporting metrics as ${format}...`);
    
    return this.makeRequest<{ url: string; filename: string }>('/operational/metrics/export', {
      method: 'POST',
      body: JSON.stringify({ format, timeRange })
    });
  }

  // System health
  async getSystemHealth(): Promise<ApiResponse<{
    api: 'healthy' | 'degraded' | 'down';
    database: 'healthy' | 'degraded' | 'down';
    websocket: 'healthy' | 'degraded' | 'down';
    externalSystems: 'healthy' | 'degraded' | 'down';
    lastUpdate: string;
  }>> {
    console.log('[REAL API] Checking system health...');
    
    return this.makeRequest<{
      api: 'healthy' | 'degraded' | 'down';
      database: 'healthy' | 'degraded' | 'down';
      websocket: 'healthy' | 'degraded' | 'down';
      externalSystems: 'healthy' | 'degraded' | 'down';
      lastUpdate: string;
    }>('/operational/system/health');
  }

  // Health check
  async checkOperationalApiHealth(): Promise<boolean> {
    try {
      console.log('[REAL API] Checking operational API health...');
      
      const response = await fetch(`${API_BASE_URL}/operational/health`);
      const isHealthy = response.ok;
      
      console.log(`[REAL API] Operational API health status: ${isHealthy ? 'OK' : 'ERROR'}`);
      return isHealthy;
      
    } catch (error) {
      console.error('[REAL API] Health check failed:', error);
      return false;
    }
  }
}

export const realOperationalService = new RealOperationalService();
export default realOperationalService;