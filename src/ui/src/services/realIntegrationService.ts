/**
 * REAL Integration Settings Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints for API configuration management
 */

import { realAuthService } from './realAuthService';

export interface APIEndpoint {
  id: string;
  name: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  url: string;
  status: 'active' | 'inactive' | 'testing';
  lastTest: Date;
  responseTime: number;
  successRate: number;
  headers: Record<string, string>;
  authentication?: {
    type: 'bearer' | 'basic' | 'api-key';
    token: string;
  };
}

export interface IntegrationConfig {
  id: string;
  name: string;
  type: 'api' | 'database' | 'file' | 'queue';
  enabled: boolean;
  configuration: Record<string, any>;
  endpoints: APIEndpoint[];
  createdAt: Date;
  updatedAt: Date;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

class RealIntegrationService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const token = realAuthService.getAuthToken();
      if (!token) {
        throw new Error('No authentication token found. Please log in.');
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
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      return { success: true, data: data as T };

    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error('[REAL API] Integration service error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  /**
   * Get all integration configurations
   */
  async getIntegrationConfigs(): Promise<ApiResponse<IntegrationConfig[]>> {
    console.log('[REAL API] Fetching integration configurations');
    return this.makeRequest<IntegrationConfig[]>('/integrations/config');
  }

  /**
   * Get specific integration configuration
   */
  async getIntegrationConfig(id: string): Promise<ApiResponse<IntegrationConfig>> {
    console.log('[REAL API] Fetching integration config:', id);
    return this.makeRequest<IntegrationConfig>(`/integrations/config/${id}`);
  }

  /**
   * Create new integration configuration
   */
  async createIntegrationConfig(config: Omit<IntegrationConfig, 'id' | 'createdAt' | 'updatedAt'>): Promise<ApiResponse<IntegrationConfig>> {
    console.log('[REAL API] Creating integration config:', config);
    
    return this.makeRequest<IntegrationConfig>('/integrations/config', {
      method: 'POST',
      body: JSON.stringify(config)
    });
  }

  /**
   * Update integration configuration
   */
  async updateIntegrationConfig(id: string, config: Partial<IntegrationConfig>): Promise<ApiResponse<IntegrationConfig>> {
    console.log('[REAL API] Updating integration config:', id, config);
    
    return this.makeRequest<IntegrationConfig>(`/integrations/config/${id}`, {
      method: 'PUT',
      body: JSON.stringify(config)
    });
  }

  /**
   * Delete integration configuration
   */
  async deleteIntegrationConfig(id: string): Promise<ApiResponse<{ message: string }>> {
    console.log('[REAL API] Deleting integration config:', id);
    
    return this.makeRequest<{ message: string }>(`/integrations/config/${id}`, {
      method: 'DELETE'
    });
  }

  /**
   * Test API endpoint
   */
  async testEndpoint(endpointId: string): Promise<ApiResponse<{ success: boolean; responseTime: number; message: string }>> {
    console.log('[REAL API] Testing endpoint:', endpointId);
    
    return this.makeRequest<{ success: boolean; responseTime: number; message: string }>(`/integrations/config/test/${endpointId}`, {
      method: 'POST'
    });
  }

  /**
   * Get endpoint statistics
   */
  async getEndpointStats(endpointId: string): Promise<ApiResponse<{ successRate: number; avgResponseTime: number; errorCount: number }>> {
    console.log('[REAL API] Fetching endpoint stats:', endpointId);
    
    return this.makeRequest<{ successRate: number; avgResponseTime: number; errorCount: number }>(`/integrations/config/stats/${endpointId}`);
  }

  /**
   * Export integration configuration
   */
  async exportConfiguration(): Promise<ApiResponse<{ configData: string; filename: string }>> {
    console.log('[REAL API] Exporting integration configuration');
    
    return this.makeRequest<{ configData: string; filename: string }>('/integrations/config/export');
  }

  /**
   * Import integration configuration
   */
  async importConfiguration(configData: string): Promise<ApiResponse<{ imported: number; errors: string[] }>> {
    console.log('[REAL API] Importing integration configuration');
    
    return this.makeRequest<{ imported: number; errors: string[] }>('/integrations/config/import', {
      method: 'POST',
      body: JSON.stringify({ configData })
    });
  }

  /**
   * Check API health
   */
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

export const realIntegrationService = new RealIntegrationService();
export default realIntegrationService;