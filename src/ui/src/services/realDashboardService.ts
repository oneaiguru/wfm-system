/**
 * REAL Dashboard Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints
 */

import { realAuthService } from './realAuthService';

export interface DashboardMetrics {
  total_employees: number;
  active_requests: number;
  pending_requests: number;
  approved_requests: number;
  total_requests_today: number;
  system_status: string;
  last_updated: string;
  
  // Legacy fields (computed from API data)
  activeAgents?: number;
  serviceLevel?: number;
  callsHandled?: number;
  avgWaitTime?: string;
  utilization?: number;
  satisfaction?: number;
  timestamp?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

class RealDashboardService {
  
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
      console.error('[REAL API] Dashboard service error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  async getDashboardMetrics(): Promise<ApiResponse<DashboardMetrics>> {
    console.log('[REAL API] Fetching dashboard metrics');
    
    return this.makeRequest<DashboardMetrics>('/metrics/dashboard', {
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

  async refreshMetrics(): Promise<ApiResponse<DashboardMetrics>> {
    console.log('[REAL API] Refreshing dashboard metrics');
    
    return this.makeRequest<DashboardMetrics>('/metrics/dashboard?refresh=true', {
      method: 'GET'
    });
  }
}

export const realDashboardService = new RealDashboardService();
export default realDashboardService;