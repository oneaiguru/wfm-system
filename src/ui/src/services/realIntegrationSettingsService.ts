/**
 * REAL Integration Settings Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints for integration configuration
 */

import { realAuthService } from './realAuthService';

export interface IntegrationConfig {
  id: string;
  name: string;
  type: 'api' | 'database' | 'file' | 'webhook' | 'service';
  provider: string;
  description: string;
  isEnabled: boolean;
  isSystem: boolean;
  version: string;
  connectionConfig: {
    endpoint?: string;
    host?: string;
    port?: number;
    database?: string;
    username?: string;
    password?: string;
    apiKey?: string;
    apiSecret?: string;
    connectionString?: string;
    timeout?: number;
    retryAttempts?: number;
    ssl?: boolean;
    headers?: Record<string, string>;
  };
  authConfig: {
    type: 'none' | 'basic' | 'bearer' | 'oauth2' | 'api_key' | 'certificate';
    credentials?: Record<string, any>;
    tokenEndpoint?: string;
    refreshToken?: string;
    expiresAt?: string;
  };
  mappingConfig: {
    inputMapping?: Record<string, string>;
    outputMapping?: Record<string, string>;
    dataTransformations?: Array<{
      field: string;
      transformation: string;
      parameters?: Record<string, any>;
    }>;
  };
  scheduleConfig?: {
    type: 'manual' | 'interval' | 'cron';
    interval?: number;
    cronExpression?: string;
    timezone?: string;
    nextRunTime?: string;
  };
  monitoringConfig: {
    healthCheckEnabled: boolean;
    healthCheckInterval: number;
    alertOnFailure: boolean;
    alertRecipients: string[];
    metricsEnabled: boolean;
    logLevel: 'debug' | 'info' | 'warn' | 'error';
  };
  status: {
    isConnected: boolean;
    lastConnected?: string;
    lastError?: string;
    errorCount: number;
    lastSync?: string;
    nextSync?: string;
  };
  permissions: {
    canEdit: boolean;
    canDelete: boolean;
    canTest: boolean;
    canViewLogs: boolean;
    requiredRole?: string;
  };
  metadata: {
    tags: string[];
    department?: string;
    owner?: string;
    documentation?: string;
    supportContact?: string;
  };
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
}

export interface IntegrationTestResult {
  success: boolean;
  message: string;
  responseTime: number;
  details?: {
    connectionStatus: boolean;
    authStatus: boolean;
    dataAccessStatus: boolean;
    errorDetails?: string;
  };
}

export interface IntegrationLog {
  id: string;
  integrationId: string;
  timestamp: string;
  level: 'debug' | 'info' | 'warn' | 'error';
  message: string;
  details?: any;
  duration?: number;
  recordsProcessed?: number;
}

export interface IntegrationMetrics {
  integrationId: string;
  period: {
    start: string;
    end: string;
  };
  totalRequests: number;
  successfulRequests: number;
  failedRequests: number;
  averageResponseTime: number;
  dataTransferred: number;
  uptime: number;
  errorRate: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

class RealIntegrationSettingsService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making integration settings request to: ${API_BASE_URL}${endpoint}`);
      
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('Authentication required. Please log in.');
      }

      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`,
          ...options.headers,
        },
        ...options,
      });

      if (!response.ok) {
        const errorText = await response.text();
        
        // Handle specific error codes
        if (response.status === 401) {
          throw new Error('Authentication failed. Please log in again.');
        } else if (response.status === 403) {
          throw new Error('Access denied. Administrator privileges required for integration settings.');
        } else if (response.status === 404) {
          throw new Error('Integration configuration not found.');
        } else if (response.status === 409) {
          throw new Error('Integration conflict. Configuration may already exist.');
        }
        
        throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return { success: true, data: data as T };

    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error('[REAL API] Integration settings request failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
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

  /**
   * Check admin permissions for integration management
   */
  async checkAdminPermissions(): Promise<ApiResponse<{ hasPermission: boolean; role: string }>> {
    console.log('[REAL API] Checking admin permissions for integration settings');
    
    return this.makeRequest<{ hasPermission: boolean; role: string }>('/integrations/config/permissions', {
      method: 'GET'
    });
  }

  /**
   * Get all integration configurations
   */
  async getAllIntegrationConfigs(): Promise<ApiResponse<IntegrationConfig[]>> {
    console.log('[REAL API] Fetching all integration configurations');
    
    return this.makeRequest<IntegrationConfig[]>('/integrations/config', {
      method: 'GET'
    });
  }

  /**
   * Get integration configuration by ID
   */
  async getIntegrationConfig(id: string): Promise<ApiResponse<IntegrationConfig>> {
    console.log('[REAL API] Fetching integration configuration:', id);
    
    return this.makeRequest<IntegrationConfig>(`/integrations/config/${encodeURIComponent(id)}`, {
      method: 'GET'
    });
  }

  /**
   * Get integration configurations by type
   */
  async getIntegrationConfigsByType(type: string): Promise<ApiResponse<IntegrationConfig[]>> {
    console.log('[REAL API] Fetching integration configurations by type:', type);
    
    return this.makeRequest<IntegrationConfig[]>(`/integrations/config/type/${encodeURIComponent(type)}`, {
      method: 'GET'
    });
  }

  /**
   * Create new integration configuration
   */
  async createIntegrationConfig(config: Omit<IntegrationConfig, 'id' | 'createdAt' | 'updatedAt' | 'createdBy' | 'updatedBy' | 'status' | 'permissions'>): Promise<ApiResponse<IntegrationConfig>> {
    console.log('[REAL API] Creating integration configuration:', config);
    
    return this.makeRequest<IntegrationConfig>('/integrations/config', {
      method: 'POST',
      body: JSON.stringify(config)
    });
  }

  /**
   * Update integration configuration
   */
  async updateIntegrationConfig(id: string, updates: Partial<IntegrationConfig>): Promise<ApiResponse<IntegrationConfig>> {
    console.log('[REAL API] Updating integration configuration:', id, updates);
    
    return this.makeRequest<IntegrationConfig>(`/integrations/config/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: JSON.stringify(updates)
    });
  }

  /**
   * Delete integration configuration
   */
  async deleteIntegrationConfig(id: string): Promise<ApiResponse<{ deleted: boolean }>> {
    console.log('[REAL API] Deleting integration configuration:', id);
    
    return this.makeRequest<{ deleted: boolean }>(`/integrations/config/${encodeURIComponent(id)}`, {
      method: 'DELETE'
    });
  }

  /**
   * Test integration connection
   */
  async testIntegrationConnection(id: string): Promise<ApiResponse<IntegrationTestResult>> {
    console.log('[REAL API] Testing integration connection:', id);
    
    return this.makeRequest<IntegrationTestResult>(`/integrations/config/${encodeURIComponent(id)}/test`, {
      method: 'POST'
    });
  }

  /**
   * Enable/disable integration
   */
  async toggleIntegrationStatus(id: string, enabled: boolean): Promise<ApiResponse<IntegrationConfig>> {
    console.log('[REAL API] Toggling integration status:', id, enabled);
    
    return this.makeRequest<IntegrationConfig>(`/integrations/config/${encodeURIComponent(id)}/toggle`, {
      method: 'POST',
      body: JSON.stringify({ enabled })
    });
  }

  /**
   * Get integration logs
   */
  async getIntegrationLogs(id: string, options?: {
    startDate?: string;
    endDate?: string;
    level?: string;
    limit?: number;
    offset?: number;
  }): Promise<ApiResponse<{ logs: IntegrationLog[]; total: number }>> {
    console.log('[REAL API] Fetching integration logs:', id, options);
    
    const params = new URLSearchParams();
    if (options?.startDate) params.append('startDate', options.startDate);
    if (options?.endDate) params.append('endDate', options.endDate);
    if (options?.level) params.append('level', options.level);
    if (options?.limit) params.append('limit', options.limit.toString());
    if (options?.offset) params.append('offset', options.offset.toString());
    
    const queryString = params.toString();
    const endpoint = queryString 
      ? `/integrations/config/${encodeURIComponent(id)}/logs?${queryString}`
      : `/integrations/config/${encodeURIComponent(id)}/logs`;
    
    return this.makeRequest<{ logs: IntegrationLog[]; total: number }>(endpoint, {
      method: 'GET'
    });
  }

  /**
   * Get integration metrics
   */
  async getIntegrationMetrics(id: string, period?: { start: string; end: string }): Promise<ApiResponse<IntegrationMetrics>> {
    console.log('[REAL API] Fetching integration metrics:', id, period);
    
    const params = new URLSearchParams();
    if (period?.start) params.append('start', period.start);
    if (period?.end) params.append('end', period.end);
    
    const queryString = params.toString();
    const endpoint = queryString 
      ? `/integrations/config/${encodeURIComponent(id)}/metrics?${queryString}`
      : `/integrations/config/${encodeURIComponent(id)}/metrics`;
    
    return this.makeRequest<IntegrationMetrics>(endpoint, {
      method: 'GET'
    });
  }

  /**
   * Validate integration configuration
   */
  async validateIntegrationConfig(config: Partial<IntegrationConfig>): Promise<ApiResponse<{
    valid: boolean;
    errors: Array<{ field: string; message: string; code: string }>;
    warnings: Array<{ field: string; message: string; code: string }>;
  }>> {
    console.log('[REAL API] Validating integration configuration:', config);
    
    return this.makeRequest<{
      valid: boolean;
      errors: Array<{ field: string; message: string; code: string }>;
      warnings: Array<{ field: string; message: string; code: string }>;
    }>('/integrations/config/validate', {
      method: 'POST',
      body: JSON.stringify(config)
    });
  }

  /**
   * Get available integration providers
   */
  async getAvailableProviders(): Promise<ApiResponse<Array<{
    id: string;
    name: string;
    type: string;
    description: string;
    configSchema: any;
    capabilities: string[];
  }>>> {
    console.log('[REAL API] Fetching available integration providers');
    
    return this.makeRequest<Array<{
      id: string;
      name: string;
      type: string;
      description: string;
      configSchema: any;
      capabilities: string[];
    }>>('/integrations/config/providers', {
      method: 'GET'
    });
  }

  /**
   * Sync integration data manually
   */
  async syncIntegrationData(id: string): Promise<ApiResponse<{
    success: boolean;
    recordsProcessed: number;
    duration: number;
    errors: string[];
  }>> {
    console.log('[REAL API] Syncing integration data:', id);
    
    return this.makeRequest<{
      success: boolean;
      recordsProcessed: number;
      duration: number;
      errors: string[];
    }>(`/integrations/config/${encodeURIComponent(id)}/sync`, {
      method: 'POST'
    });
  }

  /**
   * Get integration status for all configurations
   */
  async getIntegrationStatuses(): Promise<ApiResponse<Array<{
    id: string;
    name: string;
    isEnabled: boolean;
    isConnected: boolean;
    lastError?: string;
    nextSync?: string;
  }>>> {
    console.log('[REAL API] Fetching integration statuses');
    
    return this.makeRequest<Array<{
      id: string;
      name: string;
      isEnabled: boolean;
      isConnected: boolean;
      lastError?: string;
      nextSync?: string;
    }>>('/integrations/config/statuses', {
      method: 'GET'
    });
  }

  /**
   * Export integration configuration
   */
  async exportIntegrationConfig(id: string): Promise<ApiResponse<Blob>> {
    console.log('[REAL API] Exporting integration configuration:', id);
    
    try {
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('Authentication required. Please log in.');
      }

      const response = await fetch(`${API_BASE_URL}/integrations/config/${encodeURIComponent(id)}/export`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${authToken}`,
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
      }

      const blob = await response.blob();
      return { success: true, data: blob };

    } catch (error) {
      console.error('[REAL API] Export failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Export failed'
      };
    }
  }

  /**
   * Import integration configuration
   */
  async importIntegrationConfig(file: File): Promise<ApiResponse<{
    imported: boolean;
    integrationId?: string;
    conflicts: string[];
  }>> {
    console.log('[REAL API] Importing integration configuration from file:', file.name);
    
    const formData = new FormData();
    formData.append('file', file);

    try {
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('Authentication required. Please log in.');
      }

      const response = await fetch(`${API_BASE_URL}/integrations/config/import`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          // Don't set Content-Type for FormData, let browser set it
        },
        body: formData,
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return { success: true, data: data as { imported: boolean; integrationId?: string; conflicts: string[] } };

    } catch (error) {
      console.error('[REAL API] Import failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Import failed'
      };
    }
  }

  /**
   * Get integration health status
   */
  async getIntegrationHealth(): Promise<ApiResponse<{
    totalIntegrations: number;
    enabledIntegrations: number;
    connectedIntegrations: number;
    failedIntegrations: number;
    lastHealthCheck: string;
    issues: Array<{
      integrationId: string;
      name: string;
      issue: string;
      severity: 'low' | 'medium' | 'high' | 'critical';
    }>;
  }>> {
    console.log('[REAL API] Fetching integration health status');
    
    return this.makeRequest<{
      totalIntegrations: number;
      enabledIntegrations: number;
      connectedIntegrations: number;
      failedIntegrations: number;
      lastHealthCheck: string;
      issues: Array<{
        integrationId: string;
        name: string;
        issue: string;
        severity: 'low' | 'medium' | 'high' | 'critical';
      }>;
    }>('/integrations/config/health', {
      method: 'GET'
    });
  }

  /**
   * Schedule integration sync
   */
  async scheduleIntegrationSync(id: string, scheduleConfig: {
    type: 'manual' | 'interval' | 'cron';
    interval?: number;
    cronExpression?: string;
    timezone?: string;
  }): Promise<ApiResponse<IntegrationConfig>> {
    console.log('[REAL API] Scheduling integration sync:', id, scheduleConfig);
    
    return this.makeRequest<IntegrationConfig>(`/integrations/config/${encodeURIComponent(id)}/schedule`, {
      method: 'POST',
      body: JSON.stringify(scheduleConfig)
    });
  }
}

export const realIntegrationSettingsService = new RealIntegrationSettingsService();
export default realIntegrationSettingsService;