/**
 * REAL Employee Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints
 * Handles all employee CRUD operations with JWT authentication
 */

import { realAuthService } from './realAuthService';
import { Employee, EmployeeFilters, EmployeeStats } from '../modules/employee-management/types/employee';

export interface EmployeeCreateData {
  firstName: string;
  lastName: string;
  middleName?: string;
  email: string;
  phone: string;
  position: string;
  teamId: string;
  department: string;
  contractType: 'full-time' | 'part-time' | 'contractor';
  workLocation: string;
  hireDate: string;
  managerId?: string;
  salary?: number;
}

export interface EmployeeUpdateData extends Partial<EmployeeCreateData> {
  id: string;
}

export interface EmployeeSearchParams {
  query: string;
  filters?: {
    teams?: string[];
    positions?: string[];
    statuses?: string[];
    departments?: string[];
  };
  limit?: number;
  offset?: number;
}

export interface ProfileUpdateData {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  preferences?: {
    preferredShifts?: string[];
    notifications?: {
      email?: boolean;
      sms?: boolean;
      push?: boolean;
      scheduleChanges?: boolean;
      announcements?: boolean;
      reminders?: boolean;
    };
    language?: 'ru' | 'en' | 'ky';
    workingHours?: {
      start?: string;
      end?: string;
    };
  };
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

class RealEmployeeService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL EMPLOYEE API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('No authentication token found. Please login first.');
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
        let errorMessage = `HTTP ${response.status}: ${errorText}`;
        
        // Handle specific error codes
        if (response.status === 401) {
          errorMessage = 'Authentication failed. Please login again.';
          // Clear invalid token
          realAuthService.logout();
        } else if (response.status === 403) {
          errorMessage = 'You do not have permission to perform this action.';
        } else if (response.status === 404) {
          errorMessage = 'Employee not found.';
        } else if (response.status === 409) {
          errorMessage = 'Employee with this email already exists.';
        }
        
        throw new Error(errorMessage);
      }

      const data = await response.json();
      console.log(`[REAL EMPLOYEE API] Success response:`, data);
      
      return { success: true, data: data as T };

    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error(`[REAL EMPLOYEE API] Error:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  /**
   * Get all employees with filtering and pagination
   */
  async getEmployees(filters?: EmployeeFilters, page: number = 1, limit: number = 50): Promise<ApiResponse<PaginatedResponse<Employee>>> {
    console.log('[REAL EMPLOYEE API] Fetching employees with filters:', filters);
    
    const params = new URLSearchParams();
    params.append('page', page.toString());
    params.append('limit', limit.toString());
    
    if (filters) {
      if (filters.search) params.append('search', filters.search);
      if (filters.team) params.append('team', filters.team);
      if (filters.status) params.append('status', filters.status);
      if (filters.position) params.append('position', filters.position);
      if (filters.sortBy) params.append('sort_by', filters.sortBy);
      if (filters.sortOrder) params.append('sort_order', filters.sortOrder);
      if (filters.showInactive) params.append('include_inactive', 'true');
    }

    return this.makeRequest<PaginatedResponse<Employee>>(`/personnel/employees?${params.toString()}`);
  }

  /**
   * Get simple employee list (working endpoint)
   */
  async getEmployeesList(): Promise<ApiResponse<Employee[]>> {
    console.log('[REAL EMPLOYEE API] Fetching employees list (simple)');
    
    try {
      const response = await fetch(`${API_BASE_URL}/employees/list`, {
        headers: {
          'Content-Type': 'application/json',
          // No auth required for this endpoint
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const employees = await response.json();
      
      return {
        success: true,
        data: employees
      };
    } catch (error) {
      console.error('[REAL EMPLOYEE API] Failed to fetch employees list:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch employees'
      };
    }
  }

  /**
   * Get employee statistics
   */
  async getEmployeeStats(): Promise<ApiResponse<EmployeeStats>> {
    console.log('[REAL EMPLOYEE API] Fetching employee statistics');
    
    return this.makeRequest<EmployeeStats>('/personnel/employees/stats');
  }

  /**
   * Get single employee by ID
   */
  async getEmployee(id: string): Promise<ApiResponse<Employee>> {
    console.log('[REAL EMPLOYEE API] Fetching employee:', id);
    
    return this.makeRequest<Employee>(`/personnel/employees/${id}`);
  }

  /**
   * Create new employee
   */
  async createEmployee(employeeData: EmployeeCreateData): Promise<ApiResponse<Employee>> {
    console.log('[REAL EMPLOYEE API] Creating employee:', employeeData);
    
    return this.makeRequest<Employee>('/personnel/employees', {
      method: 'POST',
      body: JSON.stringify(employeeData)
    });
  }

  /**
   * Update existing employee
   */
  async updateEmployee(id: string, employeeData: Partial<EmployeeUpdateData>): Promise<ApiResponse<Employee>> {
    console.log('[REAL EMPLOYEE API] Updating employee:', id, employeeData);
    
    return this.makeRequest<Employee>(`/personnel/employees/${id}`, {
      method: 'PUT',
      body: JSON.stringify(employeeData)
    });
  }

  /**
   * Delete employee (soft delete - change status to terminated)
   */
  async deleteEmployee(id: string): Promise<ApiResponse<void>> {
    console.log('[REAL EMPLOYEE API] Deleting employee:', id);
    
    return this.makeRequest<void>(`/personnel/employees/${id}`, {
      method: 'DELETE'
    });
  }

  /**
   * Search employees with advanced filters
   */
  async searchEmployees(searchParams: EmployeeSearchParams): Promise<ApiResponse<PaginatedResponse<Employee>>> {
    console.log('[REAL EMPLOYEE API] Searching employees:', searchParams);
    
    return this.makeRequest<PaginatedResponse<Employee>>('/personnel/search', {
      method: 'POST',
      body: JSON.stringify(searchParams)
    });
  }

  /**
   * Get current user profile
   */
  async getMyProfile(): Promise<ApiResponse<Employee>> {
    console.log('[REAL EMPLOYEE API] Fetching current user profile');
    
    return this.makeRequest<Employee>('/profile/me');
  }

  /**
   * Update current user profile
   */
  async updateMyProfile(profileData: ProfileUpdateData): Promise<ApiResponse<Employee>> {
    console.log('[REAL EMPLOYEE API] Updating profile:', profileData);
    
    return this.makeRequest<Employee>('/profile/me', {
      method: 'PUT',
      body: JSON.stringify(profileData)
    });
  }

  /**
   * Upload employee photo
   */
  async uploadEmployeePhoto(employeeId: string, photoFile: File): Promise<ApiResponse<{ photoUrl: string }>> {
    console.log('[REAL EMPLOYEE API] Uploading photo for employee:', employeeId);
    
    try {
      const authToken = realAuthService.getAuthToken();
      if (!authToken) {
        throw new Error('No authentication token found. Please login first.');
      }

      const formData = new FormData();
      formData.append('photo', photoFile);

      const response = await fetch(`${API_BASE_URL}/personnel/employees/${employeeId}/photo`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authToken}`,
        },
        body: formData,
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Photo upload failed: ${errorText}`);
      }

      const data = await response.json();
      return { success: true, data };

    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Photo upload failed'
      };
    }
  }

  /**
   * Bulk update employees
   */
  async bulkUpdateEmployees(employeeIds: string[], updateData: Partial<EmployeeUpdateData>): Promise<ApiResponse<{ updated: number; failed: string[] }>> {
    console.log('[REAL EMPLOYEE API] Bulk updating employees:', employeeIds, updateData);
    
    return this.makeRequest<{ updated: number; failed: string[] }>('/personnel/employees/bulk', {
      method: 'PUT',
      body: JSON.stringify({
        employee_ids: employeeIds,
        update_data: updateData
      })
    });
  }

  /**
   * Export employees data
   */
  async exportEmployees(filters?: EmployeeFilters, format: 'csv' | 'xlsx' = 'csv'): Promise<ApiResponse<{ downloadUrl: string }>> {
    console.log('[REAL EMPLOYEE API] Exporting employees:', filters, format);
    
    const params = new URLSearchParams();
    params.append('format', format);
    
    if (filters) {
      if (filters.search) params.append('search', filters.search);
      if (filters.team) params.append('team', filters.team);
      if (filters.status) params.append('status', filters.status);
      if (filters.position) params.append('position', filters.position);
    }

    return this.makeRequest<{ downloadUrl: string }>(`/personnel/employees/export?${params.toString()}`, {
      method: 'POST'
    });
  }

  /**
   * Check API health before making requests
   */
  async checkApiHealth(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      return response.ok;
    } catch (error) {
      console.error('[REAL EMPLOYEE API] Health check failed:', error);
      return false;
    }
  }
}

// Export singleton instance
export const realEmployeeService = new RealEmployeeService();

// Export type definitions
export type { 
  EmployeeCreateData, 
  EmployeeUpdateData, 
  EmployeeSearchParams, 
  ProfileUpdateData,
  ApiResponse,
  PaginatedResponse
};

export default realEmployeeService;