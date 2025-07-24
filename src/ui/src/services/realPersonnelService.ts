/**
 * REAL Personnel Service - SPEC-16 Integration
 * NO MOCK DATA - connects to real INTEGRATION-OPUS personnel endpoints
 * Supports: org hierarchy, personnel management, lifecycle events
 */

import realEmployeeService from './realEmployeeService';

export interface OrganizationalHierarchy {
  id: string;
  name: string;
  type: 'company' | 'department' | 'team' | 'position';
  level: number;
  parent_id?: string;
  manager_id?: string;
  manager_name?: string;
  employee_count: number;
  children?: OrganizationalHierarchy[];
  positions?: Position[];
  employees?: Employee[];
}

export interface Position {
  id: string;
  title: string;
  title_ru: string;
  level: number;
  department_id: string;
  min_salary: number;
  max_salary: number;
  required_skills: string[];
  reports_to_position?: string;
  employee_count: number;
  is_active: boolean;
}

export interface Employee {
  id: string;
  employee_id: string;
  first_name: string;
  last_name: string;
  full_name: string;
  email: string;
  department: string;
  department_id: string;
  position: string;
  position_id: string;
  manager_id?: string;
  manager_name?: string;
  hire_date: string;
  status: 'active' | 'inactive' | 'on_leave' | 'terminated';
  performance_rating?: number;
  direct_reports?: number;
  photo_url?: string;
}

export interface LifecycleEvent {
  id: string;
  employee_id: string;
  event_type: 'hired' | 'promoted' | 'transferred' | 'leave' | 'return' | 'terminated';
  event_date: string;
  details: string;
  previous_position?: string;
  new_position?: string;
  previous_manager?: string;
  new_manager?: string;
  status: 'completed' | 'active' | 'scheduled';
  created_by: string;
  notes?: string;
}

export interface SpanOfControlAnalysis {
  manager_id: string;
  manager_name: string;
  direct_reports: number;
  recommended_range: { min: number; max: number };
  status: 'optimal' | 'high' | 'overloaded' | 'capacity';
  recommendations: string[];
}

export interface PersonnelSearchRequest {
  query?: string;
  departments?: string[];
  positions?: string[];
  managers?: string[];
  status?: string[];
  skills?: string[];
  performance_min?: number;
  hire_date_from?: string;
  hire_date_to?: string;
  availability?: 'available' | 'on_leave' | 'all';
  limit?: number;
  offset?: number;
}

export interface PersonnelApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  total_count?: number;
}

const API_BASE_URL = 'http://localhost:8001/api/v1';

class RealPersonnelService {
  
  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<PersonnelApiResponse<T>> {
    try {
      console.log(`[PERSONNEL API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
          'Accept-Language': 'ru-RU,en-US',
          ...options.headers,
        },
        ...options,
      });

      console.log(`[PERSONNEL API] Response status: ${response.status}`);

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[PERSONNEL API] Error response: ${errorText}`);
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      console.log(`[PERSONNEL API] Success response:`, data);
      
      return {
        success: true,
        data: data as T,
        total_count: data.total_count
      };

    } catch (error) {
      console.error(`[PERSONNEL API] Request failed:`, error);
      
      // NO MOCK FALLBACK - return real error
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Произошла ошибка при обращении к API персонала'
      };
    }
  }

  private getAuthToken(): string {
    // Get real JWT token from localStorage
    const token = localStorage.getItem('authToken');
    if (!token) {
      throw new Error('Токен аутентификации не найден');
    }
    return token;
  }

  // SPEC-16: Get organizational hierarchy
  async getOrganizationalHierarchy(): Promise<PersonnelApiResponse<OrganizationalHierarchy[]>> {
    console.log('[PERSONNEL API] Fetching organizational hierarchy...');
    
    return this.makeRequest<OrganizationalHierarchy[]>('/organization/hierarchy');
  }

  // SPEC-16: Get organization positions
  async getPositions(): Promise<PersonnelApiResponse<Position[]>> {
    console.log('[PERSONNEL API] Fetching organization positions...');
    
    return this.makeRequest<Position[]>('/organization/positions');
  }

  // SPEC-16: Create new employee
  async createEmployee(employeeData: Partial<Employee>): Promise<PersonnelApiResponse<Employee>> {
    console.log('[PERSONNEL API] Creating new employee:', employeeData);
    
    return this.makeRequest<Employee>('/personnel/employees', {
      method: 'POST',
      body: JSON.stringify(employeeData)
    });
  }

  // SPEC-16: Update employee
  async updateEmployee(employeeId: string, employeeData: Partial<Employee>): Promise<PersonnelApiResponse<Employee>> {
    console.log(`[PERSONNEL API] Updating employee ${employeeId}:`, employeeData);
    
    return this.makeRequest<Employee>(`/personnel/employees/${employeeId}`, {
      method: 'PUT',
      body: JSON.stringify(employeeData)
    });
  }

  // SPEC-16: Delete employee (soft delete)
  async deleteEmployee(employeeId: string): Promise<PersonnelApiResponse<{ success: boolean }>> {
    console.log(`[PERSONNEL API] Deleting employee ${employeeId}`);
    
    return this.makeRequest<{ success: boolean }>(`/personnel/employees/${employeeId}`, {
      method: 'DELETE'
    });
  }

  // SPEC-16: Reassign team member
  async reassignTeamMember(employeeId: string, newManagerId: string, reason?: string): Promise<PersonnelApiResponse<{ success: boolean }>> {
    console.log(`[PERSONNEL API] Reassigning employee ${employeeId} to manager ${newManagerId}`);
    
    return this.makeRequest<{ success: boolean }>('/teams/reassign-member', {
      method: 'POST',
      body: JSON.stringify({
        employee_id: employeeId,
        new_manager_id: newManagerId,
        reason
      })
    });
  }

  // SPEC-16: Get teams by manager
  async getTeamsByManager(managerId: string): Promise<PersonnelApiResponse<Employee[]>> {
    console.log(`[PERSONNEL API] Fetching teams for manager ${managerId}`);
    
    return this.makeRequest<Employee[]>(`/teams/by-manager/${managerId}`);
  }

  // SPEC-16: Get span of control analysis
  async getSpanOfControlAnalysis(): Promise<PersonnelApiResponse<SpanOfControlAnalysis[]>> {
    console.log('[PERSONNEL API] Fetching span of control analysis...');
    
    return this.makeRequest<SpanOfControlAnalysis[]>('/teams/span-of-control');
  }

  // SPEC-16: Advanced personnel search
  async searchPersonnel(searchRequest: PersonnelSearchRequest): Promise<PersonnelApiResponse<Employee[]>> {
    console.log('[PERSONNEL API] Advanced personnel search:', searchRequest);
    
    return this.makeRequest<Employee[]>('/personnel/search/advanced', {
      method: 'POST',
      body: JSON.stringify(searchRequest)
    });
  }

  // SPEC-16: Export employees
  async exportEmployees(format: 'csv' | 'excel' | 'pdf' = 'csv'): Promise<PersonnelApiResponse<{ download_url: string }>> {
    console.log(`[PERSONNEL API] Exporting employees in ${format} format`);
    
    return this.makeRequest<{ download_url: string }>(`/personnel/employees/export?format=${format}`);
  }

  // SPEC-16: Bulk personnel actions
  async bulkPersonnelActions(employeeIds: string[], action: string, parameters?: any): Promise<PersonnelApiResponse<{ updated_count: number }>> {
    console.log(`[PERSONNEL API] Bulk action ${action} on ${employeeIds.length} employees`);
    
    return this.makeRequest<{ updated_count: number }>('/personnel/bulk-actions', {
      method: 'POST',
      body: JSON.stringify({
        employee_ids: employeeIds,
        action,
        parameters
      })
    });
  }

  // SPEC-16: Get employee lifecycle events
  async getEmployeeLifecycle(employeeId: string): Promise<PersonnelApiResponse<LifecycleEvent[]>> {
    console.log(`[PERSONNEL API] Fetching lifecycle events for employee ${employeeId}`);
    
    return this.makeRequest<LifecycleEvent[]>(`/personnel/lifecycle/${employeeId}`);
  }

  // SPEC-16: Create lifecycle event
  async createLifecycleEvent(event: Partial<LifecycleEvent>): Promise<PersonnelApiResponse<LifecycleEvent>> {
    console.log('[PERSONNEL API] Creating lifecycle event:', event);
    
    return this.makeRequest<LifecycleEvent>('/personnel/lifecycle/events', {
      method: 'POST',
      body: JSON.stringify(event)
    });
  }

  // SPEC-16: Get upcoming lifecycle actions
  async getUpcomingLifecycleActions(): Promise<PersonnelApiResponse<LifecycleEvent[]>> {
    console.log('[PERSONNEL API] Fetching upcoming lifecycle actions...');
    
    return this.makeRequest<LifecycleEvent[]>('/personnel/lifecycle/upcoming-actions');
  }

  // SPEC-16: Create new department
  async createDepartment(departmentData: { name: string; manager_id?: string; parent_id?: string }): Promise<PersonnelApiResponse<OrganizationalHierarchy>> {
    console.log('[PERSONNEL API] Creating new department:', departmentData);
    
    return this.makeRequest<OrganizationalHierarchy>('/organization/departments', {
      method: 'POST',
      body: JSON.stringify(departmentData)
    });
  }

  // SPEC-16: Merge departments
  async mergeDepartments(departmentIds: string[], newDepartmentName: string): Promise<PersonnelApiResponse<{ success: boolean; merged_employees: number }>> {
    console.log(`[PERSONNEL API] Merging departments: ${departmentIds.join(', ')} into ${newDepartmentName}`);
    
    return this.makeRequest<{ success: boolean; merged_employees: number }>(`/organization/departments/merge`, {
      method: 'PUT',
      body: JSON.stringify({
        department_ids: departmentIds,
        new_department_name: newDepartmentName
      })
    });
  }

  // Health check for personnel API endpoints
  async checkPersonnelApiHealth(): Promise<boolean> {
    try {
      console.log('[PERSONNEL API] Checking personnel API health...');
      
      const response = await fetch(`${API_BASE_URL}/health/personnel`);
      const isHealthy = response.ok;
      
      console.log(`[PERSONNEL API] Personnel API health status: ${isHealthy ? 'OK' : 'ERROR'}`);
      return isHealthy;
      
    } catch (error) {
      console.error('[PERSONNEL API] Health check failed:', error);
      return false;
    }
  }

  // Integration with existing employee service
  async getEmployeeDetails(employeeId: string): Promise<Employee | null> {
    try {
      // Use existing employee service first
      const employee = await realEmployeeService.getEmployee(employeeId);
      if (employee) {
        return employee as Employee;
      }
      
      // Fallback to personnel API
      const result = await this.makeRequest<Employee>(`/personnel/employees/${employeeId}`);
      return result.success && result.data ? result.data : null;
      
    } catch (error) {
      console.error('[PERSONNEL API] Error getting employee details:', error);
      return null;
    }
  }
}

export const realPersonnelService = new RealPersonnelService();
export default realPersonnelService;