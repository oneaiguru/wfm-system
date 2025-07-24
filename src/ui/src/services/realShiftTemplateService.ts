// Real Shift Template Service - NO MOCK FALLBACKS
// This service makes REAL API calls to backend shift template endpoints
// If the API fails, it returns REAL errors to the user

interface ShiftTemplate {
  id: string;
  name: string;
  startTime: string;
  endTime: string;
  duration: number; // in minutes
  breakDuration: number; // in minutes
  color: string;
  type: 'day' | 'night' | 'evening' | 'flexible';
  workPattern: string; // e.g., "5/2" for 5 days on, 2 days off
  isActive: boolean;
  description?: string;
  skills?: string[];
  department?: string;
  createdAt?: string;
  updatedAt?: string;
}

interface CreateShiftTemplateRequest {
  name: string;
  startTime: string;
  endTime: string;
  duration: number;
  breakDuration: number;
  color: string;
  type: 'day' | 'night' | 'evening' | 'flexible';
  workPattern: string;
  description?: string;
  skills?: string[];
  department?: string;
}

interface UpdateShiftTemplateRequest {
  id: string;
  name?: string;
  startTime?: string;
  endTime?: string;
  duration?: number;
  breakDuration?: number;
  color?: string;
  type?: 'day' | 'night' | 'evening' | 'flexible';
  workPattern?: string;
  description?: string;
  skills?: string[];
  department?: string;
  isActive?: boolean;
}

interface ShiftTemplateListResponse {
  success: boolean;
  data?: {
    templates: ShiftTemplate[];
    total: number;
    active: number;
  };
  error?: string;
}

interface ShiftTemplateResponse {
  success: boolean;
  template?: ShiftTemplate;
  error?: string;
}

const API_BASE_URL = 'http://localhost:8001';

class RealShiftTemplateService {
  private token: string | null = null;

  constructor() {
    this.token = localStorage.getItem('authToken');
  }

  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${API_BASE_URL}${endpoint}`;
    
    const headers = {
      'Content-Type': 'application/json',
      ...(this.token && { 'Authorization': `Bearer ${this.token}` }),
      ...options.headers,
    };

    try {
      const response = await fetch(url, {
        ...options,
        headers,
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      if (error instanceof Error) {
        throw new Error(`Shift Template API Error: ${error.message}`);
      }
      throw new Error('Unknown shift template API error');
    }
  }

  // Health check to verify API connectivity
  async checkApiHealth(): Promise<{ healthy: boolean; message: string }> {
    try {
      const response = await this.makeRequest<{ status: string; service: string }>('/health');
      return {
        healthy: response.status === 'healthy',
        message: `API Health: ${response.status} - ${response.service}`
      };
    } catch (error) {
      return {
        healthy: false,
        message: error instanceof Error ? error.message : 'Health check failed'
      };
    }
  }

  // Get all shift templates
  async getShiftTemplates(includeInactive = false): Promise<ShiftTemplateListResponse> {
    try {
      const params = new URLSearchParams();
      if (includeInactive) {
        params.append('include_inactive', 'true');
      }

      const response = await this.makeRequest<ShiftTemplateListResponse>(`/api/v1/shift-templates?${params}`);
      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch shift templates'
      };
    }
  }

  // Get a specific shift template by ID
  async getShiftTemplate(templateId: string): Promise<ShiftTemplateResponse> {
    try {
      const response = await this.makeRequest<ShiftTemplateResponse>(`/api/v1/shift-templates/${templateId}`);
      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch shift template'
      };
    }
  }

  // Create a new shift template
  async createShiftTemplate(request: CreateShiftTemplateRequest): Promise<ShiftTemplateResponse> {
    try {
      const response = await this.makeRequest<ShiftTemplateResponse>('/api/v1/shift-templates', {
        method: 'POST',
        body: JSON.stringify(request),
      });

      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create shift template'
      };
    }
  }

  // Update an existing shift template
  async updateShiftTemplate(request: UpdateShiftTemplateRequest): Promise<ShiftTemplateResponse> {
    try {
      const response = await this.makeRequest<ShiftTemplateResponse>(`/api/v1/shift-templates/${request.id}`, {
        method: 'PUT',
        body: JSON.stringify(request),
      });

      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update shift template'
      };
    }
  }

  // Delete a shift template
  async deleteShiftTemplate(templateId: string): Promise<{ success: boolean; error?: string }> {
    try {
      await this.makeRequest(`/api/v1/shift-templates/${templateId}`, {
        method: 'DELETE',
      });

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete shift template'
      };
    }
  }

  // Activate/deactivate a shift template
  async toggleShiftTemplate(templateId: string, isActive: boolean): Promise<ShiftTemplateResponse> {
    try {
      const response = await this.makeRequest<ShiftTemplateResponse>(`/api/v1/shift-templates/${templateId}/toggle`, {
        method: 'PUT',
        body: JSON.stringify({ isActive }),
      });

      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to toggle shift template'
      };
    }
  }

  // Clone an existing shift template
  async cloneShiftTemplate(templateId: string, newName: string): Promise<ShiftTemplateResponse> {
    try {
      const response = await this.makeRequest<ShiftTemplateResponse>(`/api/v1/shift-templates/${templateId}/clone`, {
        method: 'POST',
        body: JSON.stringify({ name: newName }),
      });

      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to clone shift template'
      };
    }
  }

  // Get shift templates by department
  async getShiftTemplatesByDepartment(department: string): Promise<ShiftTemplateListResponse> {
    try {
      const params = new URLSearchParams({ department });
      const response = await this.makeRequest<ShiftTemplateListResponse>(`/api/v1/shift-templates/by-department?${params}`);
      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch department shift templates'
      };
    }
  }

  // Validate shift template configuration
  async validateShiftTemplate(template: Omit<CreateShiftTemplateRequest, 'name'>): Promise<{ valid: boolean; errors?: string[]; warnings?: string[] }> {
    try {
      const response = await this.makeRequest<{ valid: boolean; errors?: string[]; warnings?: string[] }>('/api/v1/shift-templates/validate', {
        method: 'POST',
        body: JSON.stringify(template),
      });

      return response;
    } catch (error) {
      return {
        valid: false,
        errors: [error instanceof Error ? error.message : 'Validation failed']
      };
    }
  }
}

// Export singleton instance
const realShiftTemplateService = new RealShiftTemplateService();
export default realShiftTemplateService;

// Export types for use in components
export type {
  ShiftTemplate,
  CreateShiftTemplateRequest,
  UpdateShiftTemplateRequest,
  ShiftTemplateListResponse,
  ShiftTemplateResponse
};