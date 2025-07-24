/**
 * REAL Vacation Scheme Service - Vacation scheme management API
 * NO MOCK DATA - connects to real INTEGRATION-OPUS endpoints
 * Following proven realWorkRuleService.ts pattern
 */

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface VacationScheme {
  id: string;
  name: string;
  description: string;
  type: 'annual' | 'sick' | 'unpaid' | 'maternity' | 'study' | 'custom';
  isActive: boolean;
  isDefault: boolean;
  configuration: VacationConfiguration;
  businessRules: BusinessRule[];
  applicableTo: ApplicabilityRule[];
  createdDate: string;
  lastModified: string;
  createdBy: string;
}

export interface VacationConfiguration {
  entitlementDays: number;
  maxConsecutiveDays: number;
  minAdvanceNotice: number; // days
  maxAdvanceBooking: number; // days
  allowPartialDays: boolean;
  requiresApproval: boolean;
  blackoutPeriods: BlackoutPeriod[];
  carryoverSettings: CarryoverSettings;
  accruralSettings: AccruralSettings;
}

export interface BlackoutPeriod {
  id: string;
  name: string;
  startDate: string;
  endDate: string;
  reason: string;
  isRecurring: boolean;
  exceptions: string[]; // User IDs who can still book
}

export interface CarryoverSettings {
  enabled: boolean;
  maxDays: number;
  expiryDate: string; // Format: MM-DD
  requiresApproval: boolean;
}

export interface AccruralSettings {
  method: 'monthly' | 'quarterly' | 'annually' | 'per_hour';
  rate: number;
  maxAccrual: number;
  resetDate: string; // Format: MM-DD
}

export interface BusinessRule {
  id: string;
  name: string;
  type: 'validation' | 'calculation' | 'notification' | 'approval';
  condition: string;
  action: string;
  isActive: boolean;
  priority: number;
}

export interface ApplicabilityRule {
  id: string;
  criteria: 'all' | 'department' | 'role' | 'employee' | 'custom';
  value: string;
  isInclude: boolean; // true = include, false = exclude
}

export interface VacationSchemeTemplate {
  id: string;
  name: string;
  description: string;
  category: 'standard' | 'industry' | 'legal' | 'custom';
  template: Partial<VacationScheme>;
  russianName: string;
}

export interface VacationValidation {
  valid: boolean;
  violations: string[];
  warnings: string[];
  conflicts: VacationConflict[];
}

export interface VacationConflict {
  type: 'overlap' | 'blackout' | 'insufficient_balance' | 'approval_required';
  message: string;
  severity: 'error' | 'warning' | 'info';
  affectedDates: string[];
}

export interface VacationBalance {
  employeeId: string;
  schemeId: string;
  currentBalance: number;
  usedDays: number;
  pendingDays: number;
  accruedDays: number;
  carryoverDays: number;
  expiryDate: string;
}

const API_BASE_URL = 'http://localhost:8001/api/v1';

class RealVacationSchemeService {
  
  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
          ...options.headers,
        },
        ...options,
      });

      console.log(`[REAL API] Response status: ${response.status}`);

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[REAL API] Error response: ${errorText}`);
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      console.log(`[REAL API] Success response:`, data);
      
      return {
        success: true,
        data: data as T
      };

    } catch (error) {
      console.error(`[REAL API] Request failed:`, error);
      
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  private getAuthToken(): string {
    const token = localStorage.getItem('authToken');
    if (!token) {
      throw new Error('No authentication token found');
    }
    return token;
  }

  // Vacation scheme management
  async getVacationSchemes(): Promise<ApiResponse<VacationScheme[]>> {
    console.log('[REAL API] Fetching vacation schemes...');
    
    return this.makeRequest<VacationScheme[]>('/vacation-schemes');
  }

  async getVacationScheme(id: string): Promise<ApiResponse<VacationScheme>> {
    console.log(`[REAL API] Fetching vacation scheme ${id}...`);
    
    return this.makeRequest<VacationScheme>(`/vacation-schemes/${id}`);
  }

  async createVacationScheme(scheme: Omit<VacationScheme, 'id' | 'createdDate' | 'lastModified' | 'createdBy'>): Promise<ApiResponse<VacationScheme>> {
    console.log('[REAL API] Creating vacation scheme:', scheme);
    
    return this.makeRequest<VacationScheme>('/vacation-schemes', {
      method: 'POST',
      body: JSON.stringify(scheme)
    });
  }

  async updateVacationScheme(id: string, scheme: Partial<VacationScheme>): Promise<ApiResponse<VacationScheme>> {
    console.log(`[REAL API] Updating vacation scheme ${id}:`, scheme);
    
    return this.makeRequest<VacationScheme>(`/vacation-schemes/${id}`, {
      method: 'PUT',
      body: JSON.stringify(scheme)
    });
  }

  async deleteVacationScheme(id: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Deleting vacation scheme ${id}...`);
    
    return this.makeRequest<{ success: boolean }>(`/vacation-schemes/${id}`, {
      method: 'DELETE'
    });
  }

  // Templates
  async getVacationSchemeTemplates(): Promise<ApiResponse<VacationSchemeTemplate[]>> {
    console.log('[REAL API] Fetching vacation scheme templates...');
    
    return this.makeRequest<VacationSchemeTemplate[]>('/vacation-schemes/templates');
  }

  async getTemplatesByCategory(category: string): Promise<ApiResponse<VacationSchemeTemplate[]>> {
    console.log(`[REAL API] Fetching templates by category ${category}...`);
    
    return this.makeRequest<VacationSchemeTemplate[]>(`/vacation-schemes/templates/category/${category}`);
  }

  // Validation
  async validateVacationScheme(scheme: Partial<VacationScheme>): Promise<ApiResponse<VacationValidation>> {
    console.log('[REAL API] Validating vacation scheme:', scheme);
    
    return this.makeRequest<VacationValidation>('/vacation-schemes/validate', {
      method: 'POST',
      body: JSON.stringify(scheme)
    });
  }

  async validateVacationRequest(
    employeeId: string,
    schemeId: string,
    startDate: string,
    endDate: string
  ): Promise<ApiResponse<VacationValidation>> {
    console.log(`[REAL API] Validating vacation request for employee ${employeeId}...`);
    
    return this.makeRequest<VacationValidation>('/vacation-schemes/validate-request', {
      method: 'POST',
      body: JSON.stringify({
        employeeId,
        schemeId,
        startDate,
        endDate
      })
    });
  }

  // Balances
  async getEmployeeVacationBalance(employeeId: string, schemeId: string): Promise<ApiResponse<VacationBalance>> {
    console.log(`[REAL API] Fetching vacation balance for employee ${employeeId}, scheme ${schemeId}...`);
    
    return this.makeRequest<VacationBalance>(`/vacation-schemes/${schemeId}/balance/${employeeId}`);
  }

  async getEmployeeAllBalances(employeeId: string): Promise<ApiResponse<VacationBalance[]>> {
    console.log(`[REAL API] Fetching all vacation balances for employee ${employeeId}...`);
    
    return this.makeRequest<VacationBalance[]>(`/employees/${employeeId}/vacation-balances`);
  }

  async updateVacationBalance(
    employeeId: string,
    schemeId: string,
    adjustment: { amount: number; reason: string; type: 'add' | 'subtract' }
  ): Promise<ApiResponse<VacationBalance>> {
    console.log(`[REAL API] Updating vacation balance for employee ${employeeId}...`);
    
    return this.makeRequest<VacationBalance>(`/vacation-schemes/${schemeId}/balance/${employeeId}`, {
      method: 'POST',
      body: JSON.stringify(adjustment)
    });
  }

  // Blackout periods
  async getBlackoutPeriods(schemeId: string): Promise<ApiResponse<BlackoutPeriod[]>> {
    console.log(`[REAL API] Fetching blackout periods for scheme ${schemeId}...`);
    
    return this.makeRequest<BlackoutPeriod[]>(`/vacation-schemes/${schemeId}/blackout-periods`);
  }

  async createBlackoutPeriod(schemeId: string, period: Omit<BlackoutPeriod, 'id'>): Promise<ApiResponse<BlackoutPeriod>> {
    console.log(`[REAL API] Creating blackout period for scheme ${schemeId}:`, period);
    
    return this.makeRequest<BlackoutPeriod>(`/vacation-schemes/${schemeId}/blackout-periods`, {
      method: 'POST',
      body: JSON.stringify(period)
    });
  }

  async updateBlackoutPeriod(schemeId: string, periodId: string, period: Partial<BlackoutPeriod>): Promise<ApiResponse<BlackoutPeriod>> {
    console.log(`[REAL API] Updating blackout period ${periodId}:`, period);
    
    return this.makeRequest<BlackoutPeriod>(`/vacation-schemes/${schemeId}/blackout-periods/${periodId}`, {
      method: 'PUT',
      body: JSON.stringify(period)
    });
  }

  async deleteBlackoutPeriod(schemeId: string, periodId: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Deleting blackout period ${periodId}...`);
    
    return this.makeRequest<{ success: boolean }>(`/vacation-schemes/${schemeId}/blackout-periods/${periodId}`, {
      method: 'DELETE'
    });
  }

  // Business rules
  async getBusinessRules(schemeId: string): Promise<ApiResponse<BusinessRule[]>> {
    console.log(`[REAL API] Fetching business rules for scheme ${schemeId}...`);
    
    return this.makeRequest<BusinessRule[]>(`/vacation-schemes/${schemeId}/business-rules`);
  }

  async createBusinessRule(schemeId: string, rule: Omit<BusinessRule, 'id'>): Promise<ApiResponse<BusinessRule>> {
    console.log(`[REAL API] Creating business rule for scheme ${schemeId}:`, rule);
    
    return this.makeRequest<BusinessRule>(`/vacation-schemes/${schemeId}/business-rules`, {
      method: 'POST',
      body: JSON.stringify(rule)
    });
  }

  async updateBusinessRule(schemeId: string, ruleId: string, rule: Partial<BusinessRule>): Promise<ApiResponse<BusinessRule>> {
    console.log(`[REAL API] Updating business rule ${ruleId}:`, rule);
    
    return this.makeRequest<BusinessRule>(`/vacation-schemes/${schemeId}/business-rules/${ruleId}`, {
      method: 'PUT',
      body: JSON.stringify(rule)
    });
  }

  async deleteBusinessRule(schemeId: string, ruleId: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Deleting business rule ${ruleId}...`);
    
    return this.makeRequest<{ success: boolean }>(`/vacation-schemes/${schemeId}/business-rules/${ruleId}`, {
      method: 'DELETE'
    });
  }

  // Duplication and export
  async duplicateVacationScheme(id: string, newName: string): Promise<ApiResponse<VacationScheme>> {
    console.log(`[REAL API] Duplicating vacation scheme ${id} as ${newName}...`);
    
    return this.makeRequest<VacationScheme>(`/vacation-schemes/${id}/duplicate`, {
      method: 'POST',
      body: JSON.stringify({ newName })
    });
  }

  async exportVacationScheme(id: string, format: 'json' | 'xml' | 'csv'): Promise<ApiResponse<{ data: string; filename: string }>> {
    console.log(`[REAL API] Exporting vacation scheme ${id} as ${format}...`);
    
    return this.makeRequest<{ data: string; filename: string }>(`/vacation-schemes/${id}/export`, {
      method: 'POST',
      body: JSON.stringify({ format })
    });
  }

  async importVacationScheme(data: string, format: 'json' | 'xml' | 'csv'): Promise<ApiResponse<VacationScheme>> {
    console.log(`[REAL API] Importing vacation scheme from ${format}...`);
    
    return this.makeRequest<VacationScheme>('/vacation-schemes/import', {
      method: 'POST',
      body: JSON.stringify({ data, format })
    });
  }

  // Analytics and reporting
  async getVacationSchemeUsageStats(schemeId: string): Promise<ApiResponse<{
    totalEmployees: number;
    activeRequests: number;
    avgDaysUsed: number;
    balanceUtilization: number;
  }>> {
    console.log(`[REAL API] Fetching usage stats for scheme ${schemeId}...`);
    
    return this.makeRequest<{
      totalEmployees: number;
      activeRequests: number;
      avgDaysUsed: number;
      balanceUtilization: number;
    }>(`/vacation-schemes/${schemeId}/stats`);
  }

  async getVacationTrends(schemeId: string, period: string): Promise<ApiResponse<{
    period: string;
    requestCount: number;
    totalDays: number;
    approvalRate: number;
  }[]>> {
    console.log(`[REAL API] Fetching vacation trends for scheme ${schemeId}...`);
    
    return this.makeRequest<{
      period: string;
      requestCount: number;
      totalDays: number;
      approvalRate: number;
    }[]>(`/vacation-schemes/${schemeId}/trends`, {
      method: 'POST',
      body: JSON.stringify({ period })
    });
  }

  // Health check
  async checkVacationSchemeApiHealth(): Promise<boolean> {
    try {
      console.log('[REAL API] Checking vacation scheme API health...');
      
      const response = await fetch(`${API_BASE_URL}/vacation-schemes/health`);
      const isHealthy = response.ok;
      
      console.log(`[REAL API] Vacation scheme API health status: ${isHealthy ? 'OK' : 'ERROR'}`);
      return isHealthy;
      
    } catch (error) {
      console.error('[REAL API] Health check failed:', error);
      return false;
    }
  }
}

export const realVacationSchemeService = new RealVacationSchemeService();
export default realVacationSchemeService;