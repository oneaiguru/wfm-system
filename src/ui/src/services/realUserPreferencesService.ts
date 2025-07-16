/**
 * REAL User Preferences Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints for user preferences management
 */

import { realAuthService } from './realAuthService';

export interface UserPreferences {
  id?: string;
  userId: string;
  notifications: {
    scheduleChanges: boolean;
    shiftReminders: boolean;
    exchangeOffers: boolean;
    requestUpdates: boolean;
    emailDigest: boolean;
    pushNotifications: boolean;
    reminderMinutes: number;
    digestFrequency: 'daily' | 'weekly' | 'never';
  };
  shiftPreferences: {
    preferredShifts: string[];
    avoidShifts: string[];
    maxConsecutiveDays: number;
    minRestHours: number;
    preferredDepartments: string[];
    maxOvertimeHours: number;
  };
  language: 'ru' | 'en' | 'ky';
  timezone: string;
  autoAcceptExchanges: {
    enabled: boolean;
    sameShiftType: boolean;
    sameDuration: boolean;
    preferredTeams: boolean;
    maxAdvanceHours: number;
  };
  personalSettings: {
    theme: 'light' | 'dark' | 'auto';
    compactView: boolean;
    showWeekNumbers: boolean;
    startWeekOnMonday: boolean;
  };
  privacy: {
    sharePreferencesWithSupervisor: boolean;
    allowAutomaticScheduling: boolean;
    visibleToColleagues: boolean;
  };
  lastModified: string;
}

export interface PreferencesValidationResult {
  valid: boolean;
  errors: Array<{
    field: string;
    message: string;
  }>;
  warnings: Array<{
    field: string;
    message: string;
  }>;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

class RealUserPreferencesService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making user preferences request to: ${API_BASE_URL}${endpoint}`);
      
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
          throw new Error('Access denied. Cannot modify these preferences.');
        } else if (response.status === 404) {
          throw new Error('User preferences not found.');
        }
        
        throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return { success: true, data: data as T };

    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error('[REAL API] User preferences request failed:', error);
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
   * Get current user's preferences
   */
  async getUserPreferences(): Promise<ApiResponse<UserPreferences>> {
    console.log('[REAL API] Fetching user preferences');
    
    return this.makeRequest<UserPreferences>('/settings/user', {
      method: 'GET'
    });
  }

  /**
   * Get preferences for specific user (admin only)
   */
  async getUserPreferencesById(userId: string): Promise<ApiResponse<UserPreferences>> {
    console.log('[REAL API] Fetching user preferences for user:', userId);
    
    return this.makeRequest<UserPreferences>(`/settings/user/${encodeURIComponent(userId)}`, {
      method: 'GET'
    });
  }

  /**
   * Update user preferences
   */
  async updateUserPreferences(preferences: Partial<UserPreferences>): Promise<ApiResponse<UserPreferences>> {
    console.log('[REAL API] Updating user preferences:', preferences);
    
    return this.makeRequest<UserPreferences>('/settings/user', {
      method: 'PUT',
      body: JSON.stringify(preferences)
    });
  }

  /**
   * Update specific preference section
   */
  async updatePreferenceSection(section: keyof UserPreferences, data: any): Promise<ApiResponse<UserPreferences>> {
    console.log('[REAL API] Updating preference section:', section, data);
    
    return this.makeRequest<UserPreferences>(`/settings/user/${section}`, {
      method: 'PATCH',
      body: JSON.stringify(data)
    });
  }

  /**
   * Reset preferences to default values
   */
  async resetUserPreferences(): Promise<ApiResponse<UserPreferences>> {
    console.log('[REAL API] Resetting user preferences to defaults');
    
    return this.makeRequest<UserPreferences>('/settings/user/reset', {
      method: 'POST'
    });
  }

  /**
   * Reset specific preference section to defaults
   */
  async resetPreferenceSection(section: keyof UserPreferences): Promise<ApiResponse<UserPreferences>> {
    console.log('[REAL API] Resetting preference section to defaults:', section);
    
    return this.makeRequest<UserPreferences>(`/settings/user/${section}/reset`, {
      method: 'POST'
    });
  }

  /**
   * Validate preferences before saving
   */
  async validateUserPreferences(preferences: Partial<UserPreferences>): Promise<ApiResponse<PreferencesValidationResult>> {
    console.log('[REAL API] Validating user preferences:', preferences);
    
    return this.makeRequest<PreferencesValidationResult>('/settings/user/validate', {
      method: 'POST',
      body: JSON.stringify(preferences)
    });
  }

  /**
   * Export user preferences as JSON
   */
  async exportUserPreferences(): Promise<ApiResponse<UserPreferences>> {
    console.log('[REAL API] Exporting user preferences');
    
    return this.makeRequest<UserPreferences>('/settings/user/export', {
      method: 'GET'
    });
  }

  /**
   * Import user preferences from JSON
   */
  async importUserPreferences(preferences: UserPreferences): Promise<ApiResponse<{ imported: boolean; conflicts: string[] }>> {
    console.log('[REAL API] Importing user preferences');
    
    return this.makeRequest<{ imported: boolean; conflicts: string[] }>('/settings/user/import', {
      method: 'POST',
      body: JSON.stringify(preferences)
    });
  }

  /**
   * Get available shift types for preferences
   */
  async getAvailableShiftTypes(): Promise<ApiResponse<Array<{ id: string; name: string; description: string; icon: string }>>> {
    console.log('[REAL API] Fetching available shift types');
    
    return this.makeRequest<Array<{ id: string; name: string; description: string; icon: string }>>('/settings/user/shift-types', {
      method: 'GET'
    });
  }

  /**
   * Get available departments for preferences
   */
  async getAvailableDepartments(): Promise<ApiResponse<Array<{ id: string; name: string; description: string }>>> {
    console.log('[REAL API] Fetching available departments');
    
    return this.makeRequest<Array<{ id: string; name: string; description: string }>>('/settings/user/departments', {
      method: 'GET'
    });
  }

  /**
   * Test notification settings
   */
  async testNotificationSettings(notificationType: string): Promise<ApiResponse<{ sent: boolean; message: string }>> {
    console.log('[REAL API] Testing notification settings:', notificationType);
    
    return this.makeRequest<{ sent: boolean; message: string }>('/settings/user/test-notification', {
      method: 'POST',
      body: JSON.stringify({ type: notificationType })
    });
  }

  /**
   * Subscribe to real-time preference updates
   */
  subscribeToPreferenceUpdates(callback: (preferences: UserPreferences) => void): () => void {
    console.log('[REAL API] Subscribing to preference updates');
    
    const authToken = realAuthService.getAuthToken();
    if (!authToken) {
      console.error('Cannot subscribe to updates: No auth token');
      return () => {};
    }

    // Create WebSocket connection for real-time updates
    const wsUrl = API_BASE_URL.replace('http', 'ws') + `/settings/user/subscribe?token=${authToken}`;
    const ws = new WebSocket(wsUrl);
    
    ws.onmessage = (event) => {
      try {
        const update = JSON.parse(event.data);
        if (update.type === 'preferences_updated') {
          callback(update.data);
        }
      } catch (error) {
        console.error('[REAL API] Error parsing preference update:', error);
      }
    };
    
    ws.onerror = (error) => {
      console.error('[REAL API] WebSocket error:', error);
    };
    
    ws.onclose = () => {
      console.log('[REAL API] Preference updates subscription closed');
    };
    
    // Return cleanup function
    return () => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.close();
      }
    };
  }
}

export const realUserPreferencesService = new RealUserPreferencesService();
export default realUserPreferencesService;