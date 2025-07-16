/**
 * REAL Alerts Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints
 */

import { realAuthService } from './realAuthService';

export interface Alert {
  id: string;
  type: 'sla_breach' | 'queue_overflow' | 'agent_status' | 'system_error' | 'performance_degradation' | 'threshold_exceeded';
  severity: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  message: string;
  description?: string;
  timestamp: string;
  source: string;
  acknowledged: boolean;
  acknowledgedBy?: string;
  acknowledgedAt?: string;
  resolved: boolean;
  resolvedBy?: string;
  resolvedAt?: string;
  metadata?: {
    queueId?: string;
    agentId?: string;
    metricId?: string;
    threshold?: number;
    currentValue?: number;
    affectedUsers?: number;
  };
  actions?: AlertAction[];
}

export interface AlertAction {
  id: string;
  label: string;
  type: 'acknowledge' | 'resolve' | 'escalate' | 'assign' | 'comment';
  requiresConfirmation?: boolean;
  data?: any;
}

export interface AlertFilters {
  severity?: string[];
  type?: string[];
  source?: string[];
  status?: 'all' | 'active' | 'acknowledged' | 'resolved';
  dateRange?: {
    start: string;
    end: string;
  };
}

export interface AlertsData {
  alerts: Alert[];
  totalCount: number;
  activeCount: number;
  criticalCount: number;
  filters: {
    availableTypes: string[];
    availableSources: string[];
  };
  lastUpdated: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

class RealAlertsService {
  
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
      console.error('[REAL API] Alerts service error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  async getActiveAlerts(filters?: AlertFilters): Promise<ApiResponse<AlertsData>> {
    console.log('[REAL API] Fetching active alerts with filters:', filters);
    
    let endpoint = '/alerts/active';
    if (filters) {
      const params = new URLSearchParams();
      if (filters.severity?.length) params.append('severity', filters.severity.join(','));
      if (filters.type?.length) params.append('type', filters.type.join(','));
      if (filters.source?.length) params.append('source', filters.source.join(','));
      if (filters.status && filters.status !== 'all') params.append('status', filters.status);
      if (filters.dateRange) {
        params.append('start_date', filters.dateRange.start);
        params.append('end_date', filters.dateRange.end);
      }
      if (params.toString()) {
        endpoint += `?${params.toString()}`;
      }
    }
    
    return this.makeRequest<AlertsData>(endpoint, {
      method: 'GET'
    });
  }

  async refreshAlerts(): Promise<ApiResponse<AlertsData>> {
    console.log('[REAL API] Refreshing alerts');
    
    return this.makeRequest<AlertsData>('/alerts/active?refresh=true', {
      method: 'GET'
    });
  }

  async acknowledgeAlert(alertId: string, comment?: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log('[REAL API] Acknowledging alert:', alertId);
    
    return this.makeRequest<{ success: boolean }>(`/alerts/${alertId}/acknowledge`, {
      method: 'POST',
      body: JSON.stringify({ comment })
    });
  }

  async resolveAlert(alertId: string, resolution: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log('[REAL API] Resolving alert:', alertId);
    
    return this.makeRequest<{ success: boolean }>(`/alerts/${alertId}/resolve`, {
      method: 'POST',
      body: JSON.stringify({ resolution })
    });
  }

  async escalateAlert(alertId: string, escalateTo: string, reason: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log('[REAL API] Escalating alert:', alertId, 'to:', escalateTo);
    
    return this.makeRequest<{ success: boolean }>(`/alerts/${alertId}/escalate`, {
      method: 'POST',
      body: JSON.stringify({ escalateTo, reason })
    });
  }

  async addAlertComment(alertId: string, comment: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log('[REAL API] Adding comment to alert:', alertId);
    
    return this.makeRequest<{ success: boolean }>(`/alerts/${alertId}/comments`, {
      method: 'POST',
      body: JSON.stringify({ comment })
    });
  }

  async getAlertHistory(alertId: string): Promise<ApiResponse<Alert[]>> {
    console.log('[REAL API] Fetching alert history:', alertId);
    
    return this.makeRequest<Alert[]>(`/alerts/${alertId}/history`, {
      method: 'GET'
    });
  }

  async createCustomAlert(alert: Partial<Alert>): Promise<ApiResponse<Alert>> {
    console.log('[REAL API] Creating custom alert:', alert);
    
    return this.makeRequest<Alert>('/alerts/custom', {
      method: 'POST',
      body: JSON.stringify(alert)
    });
  }

  async bulkAcknowledgeAlerts(alertIds: string[], comment?: string): Promise<ApiResponse<{ success: boolean; processed: number }>> {
    console.log('[REAL API] Bulk acknowledging alerts:', alertIds.length);
    
    return this.makeRequest<{ success: boolean; processed: number }>('/alerts/bulk/acknowledge', {
      method: 'POST',
      body: JSON.stringify({ alertIds, comment })
    });
  }

  async getAlertMetrics(period: string = 'today'): Promise<ApiResponse<{
    totalAlerts: number;
    alertsByType: Record<string, number>;
    alertsBySeverity: Record<string, number>;
    avgResolutionTime: number;
    acknowledgeRate: number;
  }>> {
    console.log('[REAL API] Fetching alert metrics for period:', period);
    
    return this.makeRequest(`/alerts/metrics?period=${period}`, {
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

export const realAlertsService = new RealAlertsService();
export default realAlertsService;