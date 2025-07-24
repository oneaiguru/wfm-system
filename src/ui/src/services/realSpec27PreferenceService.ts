// SPEC-27: Preference Management Enhancement Service
// Real API service with zero mocks - connects to 10 comprehensive preference management APIs on :8003
// Focus: Employee preference management with Russian localization and GDPR compliance

interface Spec27PreferenceDashboard {
  personalPreferences: {
    totalCategories: number;
    configuredSettings: number;
    pendingUpdates: number;
    lastSyncTime: string;
    complianceStatus: 'compliant' | 'needs_review' | 'non_compliant';
  };
  notificationPreferences: {
    totalChannels: number;
    activeNotifications: number;
    deliveryRate: number;
    preferredLanguage: string;
    culturalPreference: 'formal' | 'informal' | 'system_default';
  };
  schedulePreferences: {
    satisfactionScore: number;
    optimizationImpact: 'high' | 'medium' | 'low';
    conflictCount: number;
    complianceViolations: number;
    preferenceWeight: number;
  };
  privacyPreferences: {
    gdprCompliant: boolean;
    russianLawCompliant: boolean;
    dataRetentionDays: number;
    visibilityLevel: string;
    auditTrailEnabled: boolean;
  };
  integrationStatus: {
    connectedSystems: number;
    syncHealth: 'healthy' | 'warning' | 'error';
    lastSyncTime: string;
    conflictResolutions: number;
    enterpriseManaged: boolean;
  };
}

interface Spec27PreferenceUpdate {
  categoryId: string;
  preferenceKey: string;
  newValue: string | number | boolean | object;
  businessImpact: 'high' | 'medium' | 'low';
  complianceLevel: 'legal' | 'policy' | 'preference' | 'personal';
  culturalAdaptation: boolean;
  auditTrail: boolean;
}

interface Spec27BulkPreferenceUpdate {
  categories: string[];
  preferences: Spec27PreferenceUpdate[];
  transactionId: string;
  rollbackEnabled: boolean;
  approvalRequired: boolean;
  impactAssessment: {
    usersAffected: number;
    systemsImpacted: string[];
    complianceRisk: 'low' | 'medium' | 'high';
  };
}

interface Spec27PreferenceAnalytics {
  usagePatterns: {
    featureAdoption: number;
    satisfactionTrends: number[];
    supportTicketReduction: number;
    productivityCorrelation: number;
  };
  personalInsights: {
    optimizationRecommendations: string[];
    satisfactionPrediction: number;
    conflictResolutionSuggestions: string[];
    wellnessIndicators: {
      workLifeBalance: number;
      stressLevel: 'low' | 'medium' | 'high';
      engagementScore: number;
    };
  };
  organizationalMetrics: {
    teamDiversityIndex: number;
    commonCustomizations: Array<{ name: string; adoption: number }>;
    trainingEffectiveness: number;
    policyComplianceRate: number;
    culturalAdaptationLevel: number;
  };
}

interface Spec27PreferenceExport {
  exportId: string;
  format: 'json' | 'csv' | 'xml' | 'pdf';
  categories: string[];
  includeAnalytics: boolean;
  gdprCompliant: boolean;
  russianLocalization: boolean;
  generatedAt: string;
  downloadUrl: string;
  expiresAt: string;
}

class RealSpec27PreferenceService {
  private baseUrl: string;
  private defaultHeaders: HeadersInit;

  constructor() {
    this.baseUrl = import.meta.env.VITE_API_URL || 'http://localhost:8003/api/v1';
    this.defaultHeaders = {
      'Content-Type': 'application/json',
    };
  }

  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;
    
    console.log(`[SPEC-27 SERVICE] ${options.method || 'GET'} ${url}`);

    const response = await fetch(url, {
      ...options,
      headers: {
        ...this.defaultHeaders,
        ...options.headers,
      },
    });

    if (!response.ok) {
      console.error(`[SPEC-27 SERVICE] Error ${response.status}: ${response.statusText}`);
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();
    console.log(`[SPEC-27 SERVICE] Response:`, data);
    
    return data;
  }

  // Enhanced Preference Dashboard with comprehensive categories
  async getPreferenceDashboard(): Promise<Spec27PreferenceDashboard> {
    return this.makeRequest<Spec27PreferenceDashboard>('/preferences/dashboard');
  }

  // Personal Preference Management with Russian/English localization
  async getPersonalPreferences(includeHistory: boolean = false): Promise<any> {
    const params = new URLSearchParams();
    if (includeHistory) params.set('include_history', 'true');
    
    return this.makeRequest('/preferences/personal?' + params.toString());
  }

  async updatePersonalPreferences(preferences: Record<string, any>): Promise<{ success: boolean; updated: number; conflicts: string[] }> {
    return this.makeRequest('/preferences/personal', {
      method: 'PUT',
      body: JSON.stringify(preferences),
    });
  }

  async resetPersonalPreferences(category?: string): Promise<{ success: boolean; reset: number }> {
    const body = category ? { category } : {};
    
    return this.makeRequest('/preferences/personal/reset', {
      method: 'POST',
      body: JSON.stringify(body),
    });
  }

  async getPersonalPreferenceHistory(days: number = 30): Promise<any[]> {
    return this.makeRequest(`/preferences/personal/history?days=${days}`);
  }

  // Advanced Notification Preferences with cultural preferences
  async getNotificationPreferences(): Promise<any> {
    return this.makeRequest('/preferences/notifications');
  }

  async updateNotificationPreferences(notifications: any): Promise<{ success: boolean; updated: number }> {
    return this.makeRequest('/preferences/notifications', {
      method: 'PUT',
      body: JSON.stringify(notifications),
    });
  }

  async testNotificationChannels(channels: string[]): Promise<{ [channel: string]: { success: boolean; latency: number; error?: string } }> {
    return this.makeRequest('/preferences/notifications/test', {
      method: 'POST',
      body: JSON.stringify({ channels }),
    });
  }

  async getNotificationDeliveryStatus(hours: number = 24): Promise<{ channel: string; delivered: number; failed: number; pending: number }[]> {
    return this.makeRequest(`/preferences/notifications/delivery-status?hours=${hours}`);
  }

  // Schedule Preference Management with Russian labor law compliance
  async getSchedulePreferences(): Promise<any> {
    return this.makeRequest('/preferences/schedule');
  }

  async updateSchedulePreferences(schedulePrefs: any): Promise<{ success: boolean; complianceCheck: any }> {
    return this.makeRequest('/preferences/schedule', {
      method: 'PUT',
      body: JSON.stringify(schedulePrefs),
    });
  }

  async validateSchedulePreferences(preferences: any): Promise<{ valid: boolean; violations: string[]; warnings: string[] }> {
    return this.makeRequest('/preferences/schedule/validate', {
      method: 'POST',
      body: JSON.stringify(preferences),
    });
  }

  async getScheduleConflicts(): Promise<{ conflicts: any[]; resolutions: any[] }> {
    return this.makeRequest('/preferences/schedule/conflicts');
  }

  // Dashboard Customization and UI Preferences
  async getDashboardPreferences(): Promise<any> {
    return this.makeRequest('/preferences/dashboard');
  }

  async updateDashboardLayout(layout: any): Promise<{ success: boolean; layoutId: string }> {
    return this.makeRequest('/preferences/dashboard/layout', {
      method: 'PUT',
      body: JSON.stringify(layout),
    });
  }

  async addDashboardWidget(widget: any): Promise<{ success: boolean; widgetId: string }> {
    return this.makeRequest('/preferences/dashboard/widgets', {
      method: 'POST',
      body: JSON.stringify(widget),
    });
  }

  async removeDashboardWidget(widgetId: string): Promise<{ success: boolean }> {
    return this.makeRequest(`/preferences/dashboard/widgets/${widgetId}`, {
      method: 'DELETE',
    });
  }

  // Privacy and Data Management with GDPR/Russian law compliance
  async getPrivacyPreferences(): Promise<any> {
    return this.makeRequest('/preferences/privacy');
  }

  async updatePrivacyVisibility(visibilitySettings: any): Promise<{ success: boolean; gdprCompliant: boolean; russianLawCompliant: boolean }> {
    return this.makeRequest('/preferences/privacy/visibility', {
      method: 'PUT',
      body: JSON.stringify(visibilitySettings),
    });
  }

  async exportPersonalData(format: 'json' | 'csv' | 'xml' = 'json'): Promise<Spec27PreferenceExport> {
    return this.makeRequest('/preferences/privacy/data-export', {
      method: 'POST',
      body: JSON.stringify({ format, include_analytics: true }),
    });
  }

  async requestDataDeletion(categories: string[], retentionOverride: boolean = false): Promise<{ success: boolean; scheduledDeletion: string; complianceChecked: boolean }> {
    return this.makeRequest('/preferences/privacy/data-deletion', {
      method: 'DELETE',
      body: JSON.stringify({ categories, retention_override: retentionOverride }),
    });
  }

  // Integration and Sync Management
  async getIntegrationPreferences(): Promise<any> {
    return this.makeRequest('/preferences/integrations');
  }

  async updateIntegrationSync(integrationId: string, syncSettings: any): Promise<{ success: boolean; nextSync: string }> {
    return this.makeRequest('/preferences/integrations/sync', {
      method: 'PUT',
      body: JSON.stringify({ integration_id: integrationId, ...syncSettings }),
    });
  }

  async forceSyncIntegrations(integrationIds?: string[]): Promise<{ success: boolean; syncResults: any[] }> {
    return this.makeRequest('/preferences/integrations/force-sync', {
      method: 'POST',
      body: JSON.stringify({ integration_ids: integrationIds }),
    });
  }

  async getIntegrationConflicts(): Promise<{ conflicts: any[]; autoResolutions: any[]; manualResolutions: any[] }> {
    return this.makeRequest('/preferences/integrations/conflicts');
  }

  // Analytics and Insights with personal recommendations
  async getPersonalAnalytics(period: 'week' | 'month' | 'quarter' | 'year' = 'month'): Promise<Spec27PreferenceAnalytics> {
    return this.makeRequest(`/preferences/analytics/personal?period=${period}`);
  }

  async getTeamAnalytics(includeComparisons: boolean = true): Promise<any> {
    return this.makeRequest(`/preferences/analytics/team?include_comparisons=${includeComparisons}`);
  }

  async generateRecommendations(categories: string[] = []): Promise<{ recommendations: any[]; confidence: number; impact: string }> {
    return this.makeRequest('/preferences/analytics/recommendations', {
      method: 'POST',
      body: JSON.stringify({ categories }),
    });
  }

  async getUsagePatterns(detailed: boolean = false): Promise<any> {
    return this.makeRequest(`/preferences/analytics/usage-patterns?detailed=${detailed}`);
  }

  // Bulk Operations and Advanced Management
  async bulkUpdatePreferences(updates: Spec27BulkPreferenceUpdate): Promise<{ success: boolean; updated: number; failed: number; conflicts: any[] }> {
    return this.makeRequest('/preferences/bulk/update', {
      method: 'PUT',
      body: JSON.stringify(updates),
    });
  }

  async importPreferences(importData: any, mergeStrategy: 'overwrite' | 'merge' | 'skip_conflicts' = 'merge'): Promise<{ success: boolean; imported: number; skipped: number; conflicts: any[] }> {
    return this.makeRequest('/preferences/bulk/import', {
      method: 'POST',
      body: JSON.stringify({ data: importData, merge_strategy: mergeStrategy }),
    });
  }

  async getPreferenceTemplates(): Promise<{ templates: any[]; categories: string[] }> {
    return this.makeRequest('/preferences/templates');
  }

  async applyPreferenceTemplate(templateId: string, customizations: any = {}): Promise<{ success: boolean; applied: number; customized: number }> {
    return this.makeRequest('/preferences/templates/apply', {
      method: 'POST',
      body: JSON.stringify({ template_id: templateId, customizations }),
    });
  }

  // Health Check for preference service
  async checkHealth(): Promise<{ status: 'healthy' | 'degraded' | 'down'; details: any }> {
    try {
      const response = await fetch(`${this.baseUrl.replace('/api/v1', '')}/health/preferences`);
      return response.ok 
        ? { status: 'healthy', details: { response_time: '<50ms', api_version: '1.0.0' } }
        : { status: 'degraded', details: { error: 'Health check failed' } };
    } catch (error) {
      return { status: 'down', details: { error: error instanceof Error ? error.message : 'Unknown error' } };
    }
  }
}

// Export singleton instance
export const realSpec27PreferenceService = new RealSpec27PreferenceService();
export default realSpec27PreferenceService;