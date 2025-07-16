/**
 * REAL System Settings Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints for system configuration
 */

import { realAuthService } from './realAuthService';

export interface SystemSetting {
  key: string;
  value: any;
  defaultValue: any;
  dataType: 'string' | 'number' | 'boolean' | 'json' | 'password';
  category: string;
  description: string;
  isRequired: boolean;
  isReadOnly: boolean;
  validationRules?: {
    min?: number;
    max?: number;
    pattern?: string;
    options?: string[];
  };
  lastModified: string;
  modifiedBy: string;
}

export interface SystemHealth {
  status: 'healthy' | 'warning' | 'critical';
  cpuUsage: number;
  memoryUsage: number;
  diskUsage: number;
  uptime: number;
  activeConnections: number;
  timestamp: string;
}

export interface SystemConfiguration {
  settings: SystemSetting[];
  backupInfo?: {
    lastBackup: string;
    backupSize: number;
    backupLocation: string;
  };
}

export interface SettingValidationResult {
  valid: boolean;
  errors: Array<{
    key: string;
    message: string;
  }>;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

class RealSystemSettingsService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making system settings request to: ${API_BASE_URL}${endpoint}`);
      
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
          throw new Error('Access denied. Administrator privileges required.');
        } else if (response.status === 404) {
          throw new Error('System settings endpoint not found.');
        }
        
        throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return { success: true, data: data as T };

    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error('[REAL API] System settings request failed:', error);
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
   * Get system settings by category
   */
  async getSystemSettingsByCategory(category: string): Promise<ApiResponse<SystemSetting[]>> {
    console.log('[REAL API] Fetching system settings for category:', category);
    
    return this.makeRequest<SystemSetting[]>(`/settings/system?category=${encodeURIComponent(category)}`, {
      method: 'GET'
    });
  }

  /**
   * Get all system settings
   */
  async getAllSystemSettings(): Promise<ApiResponse<SystemSetting[]>> {
    console.log('[REAL API] Fetching all system settings');
    
    return this.makeRequest<SystemSetting[]>('/settings/system', {
      method: 'GET'
    });
  }

  /**
   * Get specific system setting by key
   */
  async getSystemSetting(key: string): Promise<ApiResponse<SystemSetting>> {
    console.log('[REAL API] Fetching system setting:', key);
    
    return this.makeRequest<SystemSetting>(`/settings/system/${encodeURIComponent(key)}`, {
      method: 'GET'
    });
  }

  /**
   * Update system settings
   */
  async updateSystemSettings(settings: Array<{ key: string; value: any }>): Promise<ApiResponse<SystemSetting[]>> {
    console.log('[REAL API] Updating system settings:', settings);
    
    return this.makeRequest<SystemSetting[]>('/settings/system', {
      method: 'PUT',
      body: JSON.stringify({ settings })
    });
  }

  /**
   * Update single system setting
   */
  async updateSystemSetting(key: string, value: any): Promise<ApiResponse<SystemSetting>> {
    console.log('[REAL API] Updating system setting:', key, value);
    
    return this.makeRequest<SystemSetting>(`/settings/system/${encodeURIComponent(key)}`, {
      method: 'PUT',
      body: JSON.stringify({ value })
    });
  }

  /**
   * Reset system setting to default value
   */
  async resetSystemSetting(key: string): Promise<ApiResponse<SystemSetting>> {
    console.log('[REAL API] Resetting system setting to default:', key);
    
    return this.makeRequest<SystemSetting>(`/settings/system/${encodeURIComponent(key)}/reset`, {
      method: 'POST'
    });
  }

  /**
   * Validate system settings before applying
   */
  async validateSystemSettings(settings: Array<{ key: string; value: any }>): Promise<ApiResponse<SettingValidationResult>> {
    console.log('[REAL API] Validating system settings:', settings);
    
    return this.makeRequest<SettingValidationResult>('/settings/system/validate', {
      method: 'POST',
      body: JSON.stringify({ settings })
    });
  }

  /**
   * Get system health metrics
   */
  async getSystemHealth(): Promise<ApiResponse<SystemHealth>> {
    console.log('[REAL API] Fetching system health metrics');
    
    return this.makeRequest<SystemHealth>('/settings/system/health', {
      method: 'GET'
    });
  }

  /**
   * Create configuration backup
   */
  async createConfigurationBackup(): Promise<ApiResponse<{ backupId: string; timestamp: string; size: number }>> {
    console.log('[REAL API] Creating configuration backup');
    
    return this.makeRequest<{ backupId: string; timestamp: string; size: number }>('/settings/system/backup', {
      method: 'POST'
    });
  }

  /**
   * Restore configuration from backup
   */
  async restoreConfigurationBackup(backupId: string): Promise<ApiResponse<{ restored: boolean; settings: SystemSetting[] }>> {
    console.log('[REAL API] Restoring configuration backup:', backupId);
    
    return this.makeRequest<{ restored: boolean; settings: SystemSetting[] }>(`/settings/system/backup/${backupId}/restore`, {
      method: 'POST'
    });
  }

  /**
   * Get available configuration backups
   */
  async getConfigurationBackups(): Promise<ApiResponse<Array<{ id: string; timestamp: string; size: number }>>> {
    console.log('[REAL API] Fetching configuration backups');
    
    return this.makeRequest<Array<{ id: string; timestamp: string; size: number }>>('/settings/system/backups', {
      method: 'GET'
    });
  }

  /**
   * Export system configuration as JSON
   */
  async exportSystemConfiguration(): Promise<ApiResponse<SystemConfiguration>> {
    console.log('[REAL API] Exporting system configuration');
    
    return this.makeRequest<SystemConfiguration>('/settings/system/export', {
      method: 'GET'
    });
  }

  /**
   * Import system configuration from JSON
   */
  async importSystemConfiguration(configuration: SystemConfiguration): Promise<ApiResponse<{ imported: boolean; conflicts: string[] }>> {
    console.log('[REAL API] Importing system configuration');
    
    return this.makeRequest<{ imported: boolean; conflicts: string[] }>('/settings/system/import', {
      method: 'POST',
      body: JSON.stringify(configuration)
    });
  }
}

export const realSystemSettingsService = new RealSystemSettingsService();
export default realSystemSettingsService;