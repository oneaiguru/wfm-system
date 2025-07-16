/**
 * REAL Notification Settings Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints for notification configuration
 */

import { realAuthService } from './realAuthService';

export interface NotificationTemplate {
  id: string;
  name: string;
  type: 'email' | 'sms' | 'push' | 'webhook' | 'slack' | 'teams';
  category: 'schedule' | 'request' | 'alert' | 'reminder' | 'system' | 'emergency';
  subject?: string;
  body: string;
  isHTML: boolean;
  variables: Array<{
    name: string;
    description: string;
    required: boolean;
    defaultValue?: any;
  }>;
  metadata: {
    tags: string[];
    department?: string;
    priority: 'low' | 'medium' | 'high' | 'urgent';
  };
  isActive: boolean;
  isSystem: boolean;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
}

export interface NotificationRule {
  id: string;
  name: string;
  description: string;
  triggerEvent: string;
  conditions: Array<{
    field: string;
    operator: 'equals' | 'not_equals' | 'contains' | 'not_contains' | 'greater_than' | 'less_than' | 'in' | 'not_in';
    value: any;
  }>;
  recipients: {
    users: string[];
    roles: string[];
    departments: string[];
    dynamic: {
      field?: string;
      rule?: string;
    };
  };
  channels: Array<{
    type: 'email' | 'sms' | 'push' | 'webhook' | 'slack' | 'teams';
    templateId?: string;
    config: Record<string, any>;
  }>;
  scheduling: {
    immediate: boolean;
    delay?: number;
    businessHoursOnly: boolean;
    timezone?: string;
    quietHours?: {
      start: string;
      end: string;
    };
  };
  throttling: {
    enabled: boolean;
    maxPerHour?: number;
    maxPerDay?: number;
    cooldownMinutes?: number;
  };
  isActive: boolean;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
}

export interface NotificationChannel {
  id: string;
  name: string;
  type: 'email' | 'sms' | 'push' | 'webhook' | 'slack' | 'teams';
  configuration: {
    // Email specific
    smtpHost?: string;
    smtpPort?: number;
    smtpUser?: string;
    smtpPassword?: string;
    smtpSecurity?: 'none' | 'tls' | 'ssl';
    fromAddress?: string;
    fromName?: string;
    
    // SMS specific
    provider?: string;
    apiKey?: string;
    apiSecret?: string;
    senderId?: string;
    
    // Push specific
    appId?: string;
    serverKey?: string;
    vapidKey?: string;
    
    // Webhook specific
    url?: string;
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
    headers?: Record<string, string>;
    authentication?: {
      type: 'none' | 'basic' | 'bearer' | 'api_key';
      credentials?: Record<string, any>;
    };
    
    // Slack/Teams specific
    webhookUrl?: string;
    botToken?: string;
    channelId?: string;
  };
  healthCheck: {
    enabled: boolean;
    interval: number;
    lastCheck?: string;
    isHealthy: boolean;
    errorMessage?: string;
  };
  metrics: {
    totalSent: number;
    successfulSent: number;
    failedSent: number;
    lastSent?: string;
  };
  isActive: boolean;
  isDefault: boolean;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
}

export interface NotificationLog {
  id: string;
  ruleId?: string;
  channelId: string;
  templateId?: string;
  recipient: string;
  type: 'email' | 'sms' | 'push' | 'webhook' | 'slack' | 'teams';
  status: 'pending' | 'sent' | 'delivered' | 'failed' | 'bounced' | 'cancelled';
  subject?: string;
  body: string;
  sentAt?: string;
  deliveredAt?: string;
  errorMessage?: string;
  retryCount: number;
  metadata: {
    triggerEvent?: string;
    userId?: string;
    priority: 'low' | 'medium' | 'high' | 'urgent';
    [key: string]: any;
  };
  createdAt: string;
}

export interface NotificationStats {
  period: {
    start: string;
    end: string;
  };
  totalNotifications: number;
  sentNotifications: number;
  failedNotifications: number;
  deliveryRate: number;
  avgDeliveryTime: number;
  byChannel: Array<{
    type: string;
    total: number;
    sent: number;
    failed: number;
  }>;
  byCategory: Array<{
    category: string;
    total: number;
    sent: number;
    failed: number;
  }>;
  topFailureReasons: Array<{
    reason: string;
    count: number;
  }>;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

class RealNotificationSettingsService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making notification settings request to: ${API_BASE_URL}${endpoint}`);
      
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
          throw new Error('Access denied. Notification management privileges required.');
        } else if (response.status === 404) {
          throw new Error('Notification configuration not found.');
        } else if (response.status === 409) {
          throw new Error('Notification conflict. Configuration may already exist.');
        }
        
        throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return { success: true, data: data as T };

    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error('[REAL API] Notification settings request failed:', error);
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

  // Notification Templates
  async getNotificationTemplates(): Promise<ApiResponse<NotificationTemplate[]>> {
    console.log('[REAL API] Fetching notification templates');
    
    return this.makeRequest<NotificationTemplate[]>('/notifications/config/templates', {
      method: 'GET'
    });
  }

  async createNotificationTemplate(template: Omit<NotificationTemplate, 'id' | 'createdAt' | 'updatedAt' | 'createdBy' | 'updatedBy'>): Promise<ApiResponse<NotificationTemplate>> {
    console.log('[REAL API] Creating notification template:', template);
    
    return this.makeRequest<NotificationTemplate>('/notifications/config/templates', {
      method: 'POST',
      body: JSON.stringify(template)
    });
  }

  async updateNotificationTemplate(id: string, updates: Partial<NotificationTemplate>): Promise<ApiResponse<NotificationTemplate>> {
    console.log('[REAL API] Updating notification template:', id, updates);
    
    return this.makeRequest<NotificationTemplate>(`/notifications/config/templates/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: JSON.stringify(updates)
    });
  }

  async deleteNotificationTemplate(id: string): Promise<ApiResponse<{ deleted: boolean }>> {
    console.log('[REAL API] Deleting notification template:', id);
    
    return this.makeRequest<{ deleted: boolean }>(`/notifications/config/templates/${encodeURIComponent(id)}`, {
      method: 'DELETE'
    });
  }

  // Notification Rules
  async getNotificationRules(): Promise<ApiResponse<NotificationRule[]>> {
    console.log('[REAL API] Fetching notification rules');
    
    return this.makeRequest<NotificationRule[]>('/notifications/config/rules', {
      method: 'GET'
    });
  }

  async createNotificationRule(rule: Omit<NotificationRule, 'id' | 'createdAt' | 'updatedAt' | 'createdBy' | 'updatedBy'>): Promise<ApiResponse<NotificationRule>> {
    console.log('[REAL API] Creating notification rule:', rule);
    
    return this.makeRequest<NotificationRule>('/notifications/config/rules', {
      method: 'POST',
      body: JSON.stringify(rule)
    });
  }

  async updateNotificationRule(id: string, updates: Partial<NotificationRule>): Promise<ApiResponse<NotificationRule>> {
    console.log('[REAL API] Updating notification rule:', id, updates);
    
    return this.makeRequest<NotificationRule>(`/notifications/config/rules/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: JSON.stringify(updates)
    });
  }

  async deleteNotificationRule(id: string): Promise<ApiResponse<{ deleted: boolean }>> {
    console.log('[REAL API] Deleting notification rule:', id);
    
    return this.makeRequest<{ deleted: boolean }>(`/notifications/config/rules/${encodeURIComponent(id)}`, {
      method: 'DELETE'
    });
  }

  async toggleNotificationRule(id: string, active: boolean): Promise<ApiResponse<NotificationRule>> {
    console.log('[REAL API] Toggling notification rule:', id, active);
    
    return this.makeRequest<NotificationRule>(`/notifications/config/rules/${encodeURIComponent(id)}/toggle`, {
      method: 'POST',
      body: JSON.stringify({ active })
    });
  }

  // Notification Channels
  async getNotificationChannels(): Promise<ApiResponse<NotificationChannel[]>> {
    console.log('[REAL API] Fetching notification channels');
    
    return this.makeRequest<NotificationChannel[]>('/notifications/config/channels', {
      method: 'GET'
    });
  }

  async createNotificationChannel(channel: Omit<NotificationChannel, 'id' | 'createdAt' | 'updatedAt' | 'createdBy' | 'updatedBy' | 'metrics'>): Promise<ApiResponse<NotificationChannel>> {
    console.log('[REAL API] Creating notification channel:', channel);
    
    return this.makeRequest<NotificationChannel>('/notifications/config/channels', {
      method: 'POST',
      body: JSON.stringify(channel)
    });
  }

  async updateNotificationChannel(id: string, updates: Partial<NotificationChannel>): Promise<ApiResponse<NotificationChannel>> {
    console.log('[REAL API] Updating notification channel:', id, updates);
    
    return this.makeRequest<NotificationChannel>(`/notifications/config/channels/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: JSON.stringify(updates)
    });
  }

  async deleteNotificationChannel(id: string): Promise<ApiResponse<{ deleted: boolean }>> {
    console.log('[REAL API] Deleting notification channel:', id);
    
    return this.makeRequest<{ deleted: boolean }>(`/notifications/config/channels/${encodeURIComponent(id)}`, {
      method: 'DELETE'
    });
  }

  async testNotificationChannel(id: string, testMessage?: { recipient: string; subject?: string; body: string }): Promise<ApiResponse<{ success: boolean; message: string; deliveryTime?: number }>> {
    console.log('[REAL API] Testing notification channel:', id, testMessage);
    
    return this.makeRequest<{ success: boolean; message: string; deliveryTime?: number }>(`/notifications/config/channels/${encodeURIComponent(id)}/test`, {
      method: 'POST',
      body: JSON.stringify(testMessage || {})
    });
  }

  // Notification Logs
  async getNotificationLogs(options?: {
    startDate?: string;
    endDate?: string;
    status?: string;
    type?: string;
    recipient?: string;
    limit?: number;
    offset?: number;
  }): Promise<ApiResponse<{ logs: NotificationLog[]; total: number }>> {
    console.log('[REAL API] Fetching notification logs:', options);
    
    const params = new URLSearchParams();
    if (options?.startDate) params.append('startDate', options.startDate);
    if (options?.endDate) params.append('endDate', options.endDate);
    if (options?.status) params.append('status', options.status);
    if (options?.type) params.append('type', options.type);
    if (options?.recipient) params.append('recipient', options.recipient);
    if (options?.limit) params.append('limit', options.limit.toString());
    if (options?.offset) params.append('offset', options.offset.toString());
    
    const queryString = params.toString();
    const endpoint = queryString 
      ? `/notifications/config/logs?${queryString}`
      : '/notifications/config/logs';
    
    return this.makeRequest<{ logs: NotificationLog[]; total: number }>(endpoint, {
      method: 'GET'
    });
  }

  // Notification Statistics
  async getNotificationStats(period?: { start: string; end: string }): Promise<ApiResponse<NotificationStats>> {
    console.log('[REAL API] Fetching notification statistics:', period);
    
    const params = new URLSearchParams();
    if (period?.start) params.append('start', period.start);
    if (period?.end) params.append('end', period.end);
    
    const queryString = params.toString();
    const endpoint = queryString 
      ? `/notifications/config/stats?${queryString}`
      : '/notifications/config/stats';
    
    return this.makeRequest<NotificationStats>(endpoint, {
      method: 'GET'
    });
  }

  // Send Test Notification
  async sendTestNotification(notification: {
    type: 'email' | 'sms' | 'push' | 'webhook' | 'slack' | 'teams';
    recipient: string;
    templateId?: string;
    channelId?: string;
    subject?: string;
    body: string;
    variables?: Record<string, any>;
  }): Promise<ApiResponse<{ sent: boolean; messageId?: string; estimatedDelivery?: string }>> {
    console.log('[REAL API] Sending test notification:', notification);
    
    return this.makeRequest<{ sent: boolean; messageId?: string; estimatedDelivery?: string }>('/notifications/config/test', {
      method: 'POST',
      body: JSON.stringify(notification)
    });
  }

  // Validate Notification Configuration
  async validateNotificationConfig(config: {
    type: 'template' | 'rule' | 'channel';
    data: any;
  }): Promise<ApiResponse<{
    valid: boolean;
    errors: Array<{ field: string; message: string; code: string }>;
    warnings: Array<{ field: string; message: string; code: string }>;
  }>> {
    console.log('[REAL API] Validating notification configuration:', config);
    
    return this.makeRequest<{
      valid: boolean;
      errors: Array<{ field: string; message: string; code: string }>;
      warnings: Array<{ field: string; message: string; code: string }>;
    }>('/notifications/config/validate', {
      method: 'POST',
      body: JSON.stringify(config)
    });
  }

  // Get Available Events
  async getAvailableEvents(): Promise<ApiResponse<Array<{
    id: string;
    name: string;
    description: string;
    category: string;
    variables: Array<{
      name: string;
      type: string;
      description: string;
    }>;
  }>>> {
    console.log('[REAL API] Fetching available notification events');
    
    return this.makeRequest<Array<{
      id: string;
      name: string;
      description: string;
      category: string;
      variables: Array<{
        name: string;
        type: string;
        description: string;
      }>;
    }>>('/notifications/config/events', {
      method: 'GET'
    });
  }

  // Real-time Notification Updates
  subscribeToNotificationUpdates(callback: (update: {
    type: 'sent' | 'delivered' | 'failed' | 'rule_triggered';
    data: any;
  }) => void): () => void {
    console.log('[REAL API] Subscribing to notification updates');
    
    const authToken = realAuthService.getAuthToken();
    if (!authToken) {
      console.error('Cannot subscribe to updates: No auth token');
      return () => {};
    }

    // Create WebSocket connection for real-time updates
    const wsUrl = API_BASE_URL.replace('http', 'ws') + `/notifications/config/subscribe?token=${authToken}`;
    const ws = new WebSocket(wsUrl);
    
    ws.onmessage = (event) => {
      try {
        const update = JSON.parse(event.data);
        callback(update);
      } catch (error) {
        console.error('[REAL API] Error parsing notification update:', error);
      }
    };
    
    ws.onerror = (error) => {
      console.error('[REAL API] WebSocket error:', error);
    };
    
    ws.onclose = () => {
      console.log('[REAL API] Notification updates subscription closed');
    };
    
    // Return cleanup function
    return () => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.close();
      }
    };
  }

  // Export/Import Configuration
  async exportNotificationConfig(): Promise<ApiResponse<Blob>> {
    console.log('[REAL API] Exporting notification configuration');
    
    try {
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('Authentication required. Please log in.');
      }

      const response = await fetch(`${API_BASE_URL}/notifications/config/export`, {
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

  async importNotificationConfig(file: File): Promise<ApiResponse<{
    imported: boolean;
    templates: number;
    rules: number;
    channels: number;
    conflicts: string[];
  }>> {
    console.log('[REAL API] Importing notification configuration from file:', file.name);
    
    const formData = new FormData();
    formData.append('file', file);

    try {
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('Authentication required. Please log in.');
      }

      const response = await fetch(`${API_BASE_URL}/notifications/config/import`, {
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
      return { success: true, data: data as { imported: boolean; templates: number; rules: number; channels: number; conflicts: string[] } };

    } catch (error) {
      console.error('[REAL API] Import failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Import failed'
      };
    }
  }
}

export const realNotificationSettingsService = new RealNotificationSettingsService();
export default realNotificationSettingsService;