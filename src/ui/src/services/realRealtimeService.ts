/**
 * REAL Realtime Metrics Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints
 */

import { realAuthService } from './realAuthService';

export interface RealtimeMetric {
  id: string;
  name: string;
  value: number;
  unit: string;
  trend: 'up' | 'down' | 'stable';
  changePercent: number;
  timestamp: string;
  threshold?: number;
  status: 'normal' | 'warning' | 'critical';
}

export interface CallQueueMetrics {
  queueId: string;
  queueName: string;
  callsWaiting: number;
  avgWaitTime: number;
  longestWaitTime: number;
  serviceLevel: number;
  abandonedCalls: number;
  agentsAvailable: number;
  agentsLoggedIn: number;
}

export interface RealtimeData {
  timestamp: string;
  metrics: RealtimeMetric[];
  queues: CallQueueMetrics[];
  totalCallsToday: number;
  totalAgentsOnline: number;
  overallServiceLevel: number;
  systemLoad: number;
  refreshRate: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

class RealRealtimeService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const token = realAuthService.getAuthToken();
      if (!token) {
        throw new Error('No authentication token found. Please login first.');
      }

      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
          ...options.headers,
        },
        ...options,
      });

      if (!response.ok) {
        const errorText = await response.text();
        if (response.status === 401) {
          throw new Error('Authentication failed. Please login again.');
        }
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      return { success: true, data: data as T };

    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error('[REAL API] Realtime service error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  async getRealtimeMetrics(): Promise<ApiResponse<RealtimeData>> {
    console.log('[REAL API] Fetching realtime metrics');
    
    return this.makeRequest<RealtimeData>('/metrics/realtime', {
      method: 'GET'
    });
  }

  async refreshRealtimeMetrics(): Promise<ApiResponse<RealtimeData>> {
    console.log('[REAL API] Refreshing realtime metrics');
    
    return this.makeRequest<RealtimeData>('/metrics/realtime?refresh=true', {
      method: 'GET'
    });
  }

  async getQueueMetrics(queueId?: string): Promise<ApiResponse<CallQueueMetrics[]>> {
    console.log('[REAL API] Fetching queue metrics:', queueId || 'all');
    
    const endpoint = queueId ? `/metrics/queues/${queueId}` : '/metrics/queues';
    return this.makeRequest<CallQueueMetrics[]>(endpoint, {
      method: 'GET'
    });
  }

  async getMetricHistory(metricId: string, hours: number = 24): Promise<ApiResponse<RealtimeMetric[]>> {
    console.log('[REAL API] Fetching metric history:', metricId, hours);
    
    return this.makeRequest<RealtimeMetric[]>(`/metrics/realtime/${metricId}/history?hours=${hours}`, {
      method: 'GET'
    });
  }

  async checkApiHealth(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      return response.ok;
    } catch (error) {
      console.error('[REAL API] Health check failed:', error);
      return false;
    }
  }
}

export const realRealtimeService = new RealRealtimeService();
export default realRealtimeService;