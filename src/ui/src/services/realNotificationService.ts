/**
 * REAL Notification Settings Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints for notification configuration management
 */

import { realAuthService } from './realAuthService';

export interface NotificationChannel {
  id: string;
  name: string;
  type: 'email' | 'sms' | 'push' | 'webhook' | 'slack' | 'teams';
  enabled: boolean;
  configuration: Record<string, any>;
  testEndpoint?: string;
  lastTested?: Date;
  status: 'active' | 'inactive' | 'error';
}

export interface NotificationTemplate {
  id: string;
  name: string;
  type: 'schedule_change' | 'shift_reminder' | 'time_off_approval' | 'alert' | 'report';
  subject: string;
  body: string;
  variables: string[];
  channels: string[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface NotificationRule {
  id: string;
  name: string;
  description: string;
  event: string;
  conditions: Array<{
    field: string;
    operator: 'equals' | 'not_equals' | 'contains' | 'greater_than' | 'less_than';
    value: any;
  }>;
  actions: Array<{
    type: 'send_notification' | 'create_alert' | 'log_event';
    configuration: Record<string, any>;
  }>;
  priority: 'low' | 'medium' | 'high' | 'critical';
  enabled: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface NotificationSettings {
  globalEnabled: boolean;
  defaultChannels: string[];
  quietHours: {
    enabled: boolean;
    startTime: string;
    endTime: string;
    timezone: string;
  };
  rateLimiting: {
    enabled: boolean;
    maxPerHour: number;
    maxPerDay: number;
  };
  retryPolicy: {
    enabled: boolean;
    maxRetries: number;
    retryDelayMinutes: number;
  };
}

export interface NotificationStats {
  totalSent: number;
  deliveryRate: number;
  channelStats: Array<{
    channel: string;
    sent: number;
    delivered: number;
    failed: number;
  }>;
  recentActivity: Array<{
    timestamp: Date;
    type: string;
    recipient: string;
    channel: string;
    status: 'sent' | 'delivered' | 'failed';
  }>;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

class RealNotificationService {
  
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
      console.error('[REAL API] Notification service error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  /**
   * Get notification settings
   */
  async getNotificationSettings(): Promise<ApiResponse<NotificationSettings>> {
    console.log('[REAL API] Fetching notification settings');
    return this.makeRequest<NotificationSettings>('/notifications/config');
  }

  /**
   * Update notification settings
   */
  async updateNotificationSettings(settings: NotificationSettings): Promise<ApiResponse<NotificationSettings>> {
    console.log('[REAL API] Updating notification settings:', settings);
    
    return this.makeRequest<NotificationSettings>('/notifications/config', {
      method: 'PUT',
      body: JSON.stringify(settings)
    });
  }

  /**
   * Get all notification channels
   */
  async getNotificationChannels(): Promise<ApiResponse<NotificationChannel[]>> {
    console.log('[REAL API] Fetching notification channels');
    return this.makeRequest<NotificationChannel[]>('/notifications/config/channels');
  }

  /**
   * Create notification channel
   */
  async createNotificationChannel(channel: Omit<NotificationChannel, 'id' | 'lastTested' | 'status'>): Promise<ApiResponse<NotificationChannel>> {
    console.log('[REAL API] Creating notification channel:', channel);
    
    return this.makeRequest<NotificationChannel>('/notifications/config/channels', {
      method: 'POST',
      body: JSON.stringify(channel)
    });
  }

  /**
   * Update notification channel
   */
  async updateNotificationChannel(id: string, channel: Partial<NotificationChannel>): Promise<ApiResponse<NotificationChannel>> {
    console.log('[REAL API] Updating notification channel:', id, channel);
    
    return this.makeRequest<NotificationChannel>(`/notifications/config/channels/${id}`, {
      method: 'PUT',
      body: JSON.stringify(channel)
    });
  }

  /**
   * Delete notification channel
   */
  async deleteNotificationChannel(id: string): Promise<ApiResponse<{ message: string }>> {
    console.log('[REAL API] Deleting notification channel:', id);
    
    return this.makeRequest<{ message: string }>(`/notifications/config/channels/${id}`, {
      method: 'DELETE'
    });
  }

  /**
   * Test notification channel
   */
  async testNotificationChannel(id: string, testMessage?: string): Promise<ApiResponse<{ success: boolean; message: string; responseTime: number }>> {
    console.log('[REAL API] Testing notification channel:', id);
    
    return this.makeRequest<{ success: boolean; message: string; responseTime: number }>(`/notifications/config/channels/${id}/test`, {
      method: 'POST',
      body: JSON.stringify({ message: testMessage || 'Test notification from WFM system' })
    });
  }

  /**
   * Get notification templates
   */
  async getNotificationTemplates(): Promise<ApiResponse<NotificationTemplate[]>> {
    console.log('[REAL API] Fetching notification templates');
    return this.makeRequest<NotificationTemplate[]>('/notifications/config/templates');
  }

  /**
   * Create notification template
   */
  async createNotificationTemplate(template: Omit<NotificationTemplate, 'id' | 'createdAt' | 'updatedAt'>): Promise<ApiResponse<NotificationTemplate>> {
    console.log('[REAL API] Creating notification template:', template);
    
    return this.makeRequest<NotificationTemplate>('/notifications/config/templates', {
      method: 'POST',
      body: JSON.stringify(template)
    });
  }

  /**
   * Update notification template
   */
  async updateNotificationTemplate(id: string, template: Partial<NotificationTemplate>): Promise<ApiResponse<NotificationTemplate>> {
    console.log('[REAL API] Updating notification template:', id, template);
    
    return this.makeRequest<NotificationTemplate>(`/notifications/config/templates/${id}`, {
      method: 'PUT',
      body: JSON.stringify(template)
    });
  }

  /**
   * Delete notification template
   */
  async deleteNotificationTemplate(id: string): Promise<ApiResponse<{ message: string }>> {
    console.log('[REAL API] Deleting notification template:', id);
    
    return this.makeRequest<{ message: string }>(`/notifications/config/templates/${id}`, {
      method: 'DELETE'
    });
  }

  /**
   * Get notification rules
   */
  async getNotificationRules(): Promise<ApiResponse<NotificationRule[]>> {
    console.log('[REAL API] Fetching notification rules');
    return this.makeRequest<NotificationRule[]>('/notifications/config/rules');
  }

  /**
   * Create notification rule
   */
  async createNotificationRule(rule: Omit<NotificationRule, 'id' | 'createdAt' | 'updatedAt'>): Promise<ApiResponse<NotificationRule>> {
    console.log('[REAL API] Creating notification rule:', rule);
    
    return this.makeRequest<NotificationRule>('/notifications/config/rules', {
      method: 'POST',
      body: JSON.stringify(rule)
    });
  }

  /**
   * Update notification rule
   */
  async updateNotificationRule(id: string, rule: Partial<NotificationRule>): Promise<ApiResponse<NotificationRule>> {
    console.log('[REAL API] Updating notification rule:', id, rule);
    
    return this.makeRequest<NotificationRule>(`/notifications/config/rules/${id}`, {
      method: 'PUT',
      body: JSON.stringify(rule)
    });
  }

  /**
   * Delete notification rule
   */
  async deleteNotificationRule(id: string): Promise<ApiResponse<{ message: string }>> {
    console.log('[REAL API] Deleting notification rule:', id);
    
    return this.makeRequest<{ message: string }>(`/notifications/config/rules/${id}`, {
      method: 'DELETE'
    });
  }

  /**
   * Get notification statistics
   */
  async getNotificationStats(days: number = 7): Promise<ApiResponse<NotificationStats>> {
    console.log('[REAL API] Fetching notification statistics for', days, 'days');
    return this.makeRequest<NotificationStats>(`/notifications/config/stats?days=${days}`);
  }

  /**
   * Send test notification
   */
  async sendTestNotification(templateId: string, recipient: string, channels: string[]): Promise<ApiResponse<{ message: string; sentTo: string[] }>> {
    console.log('[REAL API] Sending test notification:', templateId, recipient, channels);
    
    return this.makeRequest<{ message: string; sentTo: string[] }>('/notifications/config/test', {
      method: 'POST',
      body: JSON.stringify({ templateId, recipient, channels })
    });
  }

  /**
   * Get notification history
   */
  async getNotificationHistory(limit: number = 50, type?: string): Promise<ApiResponse<Array<{ id: string; timestamp: Date; type: string; recipient: string; channel: string; status: string; message: string }>>> {
    console.log('[REAL API] Fetching notification history, limit:', limit, 'type:', type);
    
    const params = new URLSearchParams({ limit: limit.toString() });
    if (type) params.append('type', type);
    
    return this.makeRequest<Array<{ id: string; timestamp: Date; type: string; recipient: string; channel: string; status: string; message: string }>>(`/notifications/config/history?${params}`);
  }

  /**
   * Clear notification history
   */
  async clearNotificationHistory(): Promise<ApiResponse<{ message: string; clearedCount: number }>> {
    console.log('[REAL API] Clearing notification history');
    
    return this.makeRequest<{ message: string; clearedCount: number }>('/notifications/config/history', {
      method: 'DELETE'
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

export const realNotificationService = new RealNotificationService();
export default realNotificationService;