/**
 * REAL Work Rule Service - Work rule management API
 * NO MOCK DATA - connects to real INTEGRATION-OPUS endpoints
 * Following proven realDashboardService.ts pattern
 */

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface WorkRule {
  id: string;
  name: string;
  mode: 'with_rotation' | 'without_rotation';
  timezone: string;
  shifts: WorkShift[];
  constraints: {
    minHoursBetweenShifts: number;
    maxConsecutiveHours: number;
    maxConsecutiveDays: number;
  };
  rotationPattern?: string;
  holidayConsideration: boolean;
  isActive: boolean;
  createdDate: string;
  lastModified: string;
}

export interface WorkShift {
  id: string;
  name: string;
  startTime: string;
  endTime: string;
  duration: number;
  type: 'standard' | 'split' | 'flexible';
  breaks?: Break[];
  isActive: boolean;
}

export interface Break {
  type: 'lunch' | 'short' | 'technical';
  duration: number;
  startTime: string;
  paid: boolean;
}

export interface WorkRuleTemplate {
  id: string;
  name: string;
  description: string;
  category: string;
  template: Partial<WorkRule>;
  russianName: string;
}

const API_BASE_URL = 'http://localhost:8000/api/v1';

class RealWorkRuleService {
  
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

  async getWorkRules(): Promise<ApiResponse<WorkRule[]>> {
    console.log('[REAL API] Fetching work rules...');
    
    return this.makeRequest<WorkRule[]>('/work-rules');
  }

  async getWorkRule(id: string): Promise<ApiResponse<WorkRule>> {
    console.log(`[REAL API] Fetching work rule ${id}...`);
    
    return this.makeRequest<WorkRule>(`/work-rules/${id}`);
  }

  async createWorkRule(workRule: Omit<WorkRule, 'id' | 'createdDate' | 'lastModified'>): Promise<ApiResponse<WorkRule>> {
    console.log('[REAL API] Creating work rule:', workRule);
    
    return this.makeRequest<WorkRule>('/work-rules', {
      method: 'POST',
      body: JSON.stringify(workRule)
    });
  }

  async updateWorkRule(id: string, workRule: Partial<WorkRule>): Promise<ApiResponse<WorkRule>> {
    console.log(`[REAL API] Updating work rule ${id}:`, workRule);
    
    return this.makeRequest<WorkRule>(`/work-rules/${id}`, {
      method: 'PUT',
      body: JSON.stringify(workRule)
    });
  }

  async deleteWorkRule(id: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Deleting work rule ${id}...`);
    
    return this.makeRequest<{ success: boolean }>(`/work-rules/${id}`, {
      method: 'DELETE'
    });
  }

  async getWorkRuleTemplates(): Promise<ApiResponse<WorkRuleTemplate[]>> {
    console.log('[REAL API] Fetching work rule templates...');
    
    return this.makeRequest<WorkRuleTemplate[]>('/work-rules/templates');
  }

  async validateWorkRule(workRule: Partial<WorkRule>): Promise<ApiResponse<{ valid: boolean; violations: string[] }>> {
    console.log('[REAL API] Validating work rule:', workRule);
    
    return this.makeRequest<{ valid: boolean; violations: string[] }>('/work-rules/validate', {
      method: 'POST',
      body: JSON.stringify(workRule)
    });
  }

  async getTimezones(): Promise<ApiResponse<string[]>> {
    console.log('[REAL API] Fetching available timezones...');
    
    return this.makeRequest<string[]>('/work-rules/timezones');
  }

  async duplicateWorkRule(id: string, newName: string): Promise<ApiResponse<WorkRule>> {
    console.log(`[REAL API] Duplicating work rule ${id} as ${newName}...`);
    
    return this.makeRequest<WorkRule>(`/work-rules/${id}/duplicate`, {
      method: 'POST',
      body: JSON.stringify({ newName })
    });
  }

  // Health check
  async checkWorkRuleApiHealth(): Promise<boolean> {
    try {
      console.log('[REAL API] Checking work rule API health...');
      
      const response = await fetch(`${API_BASE_URL}/work-rules/health`);
      const isHealthy = response.ok;
      
      console.log(`[REAL API] Work rule API health status: ${isHealthy ? 'OK' : 'ERROR'}`);
      return isHealthy;
      
    } catch (error) {
      console.error('[REAL API] Health check failed:', error);
      return false;
    }
  }
}

export const realWorkRuleService = new RealWorkRuleService();
export default realWorkRuleService;