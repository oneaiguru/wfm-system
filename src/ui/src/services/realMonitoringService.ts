/**
 * Real Monitoring Service - Connects to SPEC-15 Real-time Monitoring APIs
 * NO MOCK DATA - Live system alerts and monitoring
 */

import { realAuthService } from './realAuthService';

export interface MonitoringAlert {
  alert_id: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  category: 'staffing' | 'queue' | 'system' | 'performance';
  title: string;
  description: string;
  current_value: number;
  threshold_value: number;
  triggered_at: string;
  duration: string;
  department?: string;
  auto_actions_taken: string[];
  suggested_actions: string[];
  escalation_level: number;
  acknowledged: boolean;
  acknowledged_by?: string;
  acknowledged_at?: string;
  affected_systems?: string[];
  trend?: 'increasing' | 'decreasing' | 'stable';
}

export interface MonitoringResponse {
  alerts: MonitoringAlert[];
  summary: {
    total_alerts: number;
    critical_alerts: number;
    high_alerts: number;
    medium_alerts: number;
    low_alerts: number;
    unacknowledged: number;
  };
  escalation_summary: {
    level_0: number;
    level_1: number;
    level_2: number;
  };
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

class RealMonitoringService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[MONITORING API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const token = realAuthService.getAuthToken();
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token ? `Bearer ${token}` : '',
          ...options.headers,
        },
        ...options,
      });

      if (!response.ok) {
        throw new Error(`API request failed: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      console.log(`[MONITORING API] Response from ${endpoint}:`, data);
      
      return {
        success: true,
        data: data
      };

    } catch (error) {
      console.error(`[MONITORING API] Error calling ${endpoint}:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  async getActiveAlerts(): Promise<ApiResponse<MonitoringResponse>> {
    return this.makeRequest<MonitoringResponse>('/monitoring/alerts/active');
  }

  async acknowledgeAlert(alertId: string): Promise<ApiResponse<any>> {
    return this.makeRequest(`/monitoring/alerts/${alertId}/acknowledge`, {
      method: 'POST'
    });
  }

  async checkApiHealth(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      return response.ok;
    } catch (error) {
      console.error('[MONITORING API] Health check failed:', error);
      return false;
    }
  }
}

export const realMonitoringService = new RealMonitoringService();
export default realMonitoringService;