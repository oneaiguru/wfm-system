/**
 * REAL Performance Metrics Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints
 */

import { realAuthService } from './realAuthService';

export interface PerformanceMetric {
  id: string;
  name: string;
  value: number;
  target: number;
  unit: string;
  category: 'efficiency' | 'quality' | 'productivity' | 'satisfaction';
  trend: 'up' | 'down' | 'stable';
  changePercent: number;
  period: string;
  lastUpdated: string;
  description: string;
}

export interface AgentPerformance {
  agentId: string;
  agentName: string;
  metrics: {
    callsHandled: number;
    avgHandleTime: number;
    customerSatisfaction: number;
    firstCallResolution: number;
    scheduleAdherence: number;
    utilizationRate: number;
  };
  rank: number;
  totalAgents: number;
  period: string;
}

export interface TeamPerformance {
  teamId: string;
  teamName: string;
  agentCount: number;
  metrics: {
    teamEfficiency: number;
    avgCustomerSatisfaction: number;
    teamUtilization: number;
    qualityScore: number;
    targetAchievement: number;
  };
  period: string;
}

export interface PerformanceData {
  overallMetrics: PerformanceMetric[];
  agentPerformance: AgentPerformance[];
  teamPerformance: TeamPerformance[];
  period: string;
  lastUpdated: string;
  benchmarks: {
    industry: number;
    internal: number;
    target: number;
  };
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

class RealPerformanceService {
  
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
      console.error('[REAL API] Performance service error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  async getPerformanceMetrics(period: string = 'today'): Promise<ApiResponse<PerformanceData>> {
    console.log('[REAL API] Fetching performance metrics for period:', period);
    
    return this.makeRequest<PerformanceData>(`/metrics/performance?period=${period}`, {
      method: 'GET'
    });
  }

  async refreshPerformanceMetrics(period: string = 'today'): Promise<ApiResponse<PerformanceData>> {
    console.log('[REAL API] Refreshing performance metrics for period:', period);
    
    return this.makeRequest<PerformanceData>(`/metrics/performance?period=${period}&refresh=true`, {
      method: 'GET'
    });
  }

  async getAgentPerformance(agentId: string, period: string = 'today'): Promise<ApiResponse<AgentPerformance>> {
    console.log('[REAL API] Fetching agent performance:', agentId, period);
    
    return this.makeRequest<AgentPerformance>(`/metrics/performance/agents/${agentId}?period=${period}`, {
      method: 'GET'
    });
  }

  async getTeamPerformance(teamId: string, period: string = 'today'): Promise<ApiResponse<TeamPerformance>> {
    console.log('[REAL API] Fetching team performance:', teamId, period);
    
    return this.makeRequest<TeamPerformance>(`/metrics/performance/teams/${teamId}?period=${period}`, {
      method: 'GET'
    });
  }

  async getPerformanceTrends(metricId: string, days: number = 30): Promise<ApiResponse<PerformanceMetric[]>> {
    console.log('[REAL API] Fetching performance trends:', metricId, days);
    
    return this.makeRequest<PerformanceMetric[]>(`/metrics/performance/${metricId}/trends?days=${days}`, {
      method: 'GET'
    });
  }

  async exportPerformanceReport(period: string, format: 'pdf' | 'excel' = 'pdf'): Promise<ApiResponse<{ downloadUrl: string }>> {
    console.log('[REAL API] Exporting performance report:', period, format);
    
    return this.makeRequest<{ downloadUrl: string }>(`/metrics/performance/export?period=${period}&format=${format}`, {
      method: 'POST'
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

export const realPerformanceService = new RealPerformanceService();
export default realPerformanceService;