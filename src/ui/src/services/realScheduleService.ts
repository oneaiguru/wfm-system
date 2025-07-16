// Real Schedule Service - NO MOCK FALLBACKS
// This service makes REAL API calls to backend schedule endpoints
// If the API fails, it returns REAL errors to the user

interface Employee {
  id: number;
  employeeId: string;
  firstName: string;
  lastName: string;
  fullName: string;
  role: string;
  scheduledHours: number;
  plannedHours: number;
  photo?: string;
  skills: string[];
  isActive: boolean;
  department?: string;
  shift?: string;
  email?: string;
}

interface Shift {
  id: string;
  employeeId: number;
  startTime: string;
  endTime: string;
  date: string;
  shiftType: string;
  status: 'scheduled' | 'confirmed' | 'completed' | 'cancelled';
  skills: string[];
  breakTimes?: {
    start: string;
    end: string;
    type: 'break' | 'lunch';
  }[];
}

interface ScheduleRequest {
  startDate: string;
  endDate: string;
  employeeIds?: number[];
  departments?: string[];
  includeShifts?: boolean;
}

interface ScheduleResponse {
  success: boolean;
  data?: {
    employees: Employee[];
    shifts: Shift[];
    metadata: {
      totalEmployees: number;
      totalShifts: number;
      coverage: number;
      generatedAt: string;
    };
  };
  error?: string;
}

interface CreateShiftRequest {
  employeeId: number;
  startTime: string;
  endTime: string;
  date: string;
  shiftType: string;
  skills: string[];
  notes?: string;
}

interface UpdateShiftRequest {
  shiftId: string;
  startTime?: string;
  endTime?: string;
  status?: 'scheduled' | 'confirmed' | 'completed' | 'cancelled';
  notes?: string;
}

interface ScheduleOptimizationRequest {
  startDate: string;
  endDate: string;
  constraints: {
    minCoverage: number;
    maxOvertimeHours: number;
    skillRequirements: { [skill: string]: number };
  };
  preferences: {
    balanceWorkload: boolean;
    respectTimeOff: boolean;
    minimizeCosts: boolean;
  };
}

const API_BASE_URL = 'http://localhost:8000';

class RealScheduleService {
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
        throw new Error(`Schedule API Error: ${error.message}`);
      }
      throw new Error('Unknown schedule API error');
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

  // Get current schedule data
  async getCurrentSchedule(): Promise<ScheduleResponse> {
    try {
      const response = await this.makeRequest<ScheduleResponse>('/api/v1/schedules/current');
      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch current schedule'
      };
    }
  }

  // Get employees and their schedules
  async getScheduleData(request: ScheduleRequest): Promise<ScheduleResponse> {
    try {
      const params = new URLSearchParams({
        start_date: request.startDate,
        end_date: request.endDate,
        include_shifts: request.includeShifts ? 'true' : 'false'
      });

      if (request.employeeIds?.length) {
        params.append('employee_ids', request.employeeIds.join(','));
      }

      if (request.departments?.length) {
        params.append('departments', request.departments.join(','));
      }

      const response = await this.makeRequest<ScheduleResponse>(`/api/v1/schedules?${params}`);
      return response;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch schedule data'
      };
    }
  }

  // Get employees only (for grid display)
  async getEmployees(includeInactive = false): Promise<{ success: boolean; employees?: Employee[]; error?: string }> {
    try {
      const params = new URLSearchParams();
      if (includeInactive) {
        params.append('include_inactive', 'true');
      }

      const response = await this.makeRequest<{ employees: Employee[] }>(`/api/v1/personnel/employees?${params}`);
      
      return {
        success: true,
        employees: response.employees
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch employees'
      };
    }
  }

  // Get shifts for a specific time period
  async getShifts(startDate: string, endDate: string, employeeIds?: number[]): Promise<{ success: boolean; shifts?: Shift[]; error?: string }> {
    try {
      const params = new URLSearchParams({
        start_date: startDate,
        end_date: endDate
      });

      if (employeeIds?.length) {
        params.append('employee_ids', employeeIds.join(','));
      }

      const response = await this.makeRequest<{ shifts: Shift[] }>(`/api/v1/schedules/shifts?${params}`);
      
      return {
        success: true,
        shifts: response.shifts
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch shifts'
      };
    }
  }

  // Create a new shift
  async createShift(request: CreateShiftRequest): Promise<{ success: boolean; shift?: Shift; error?: string }> {
    try {
      const response = await this.makeRequest<{ shift: Shift }>('/api/v1/schedules/shifts', {
        method: 'POST',
        body: JSON.stringify(request),
      });

      return {
        success: true,
        shift: response.shift
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create shift'
      };
    }
  }

  // Update an existing shift
  async updateShift(request: UpdateShiftRequest): Promise<{ success: boolean; shift?: Shift; error?: string }> {
    try {
      const response = await this.makeRequest<{ shift: Shift }>(`/api/v1/schedules/shifts/${request.shiftId}`, {
        method: 'PUT',
        body: JSON.stringify(request),
      });

      return {
        success: true,
        shift: response.shift
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update shift'
      };
    }
  }

  // Delete a shift
  async deleteShift(shiftId: string): Promise<{ success: boolean; error?: string }> {
    try {
      await this.makeRequest(`/api/v1/schedules/shifts/${shiftId}`, {
        method: 'DELETE',
      });

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete shift'
      };
    }
  }

  // Move/reassign a shift
  async moveShift(shiftId: string, newEmployeeId: number, newStartTime?: string, newEndTime?: string): Promise<{ success: boolean; shift?: Shift; error?: string }> {
    try {
      const updateData: any = { employeeId: newEmployeeId };
      if (newStartTime) updateData.startTime = newStartTime;
      if (newEndTime) updateData.endTime = newEndTime;

      const response = await this.makeRequest<{ shift: Shift }>(`/api/v1/schedules/shifts/${shiftId}/move`, {
        method: 'PUT',
        body: JSON.stringify(updateData),
      });

      return {
        success: true,
        shift: response.shift
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to move shift'
      };
    }
  }

  // Generate optimized schedule
  async optimizeSchedule(request: ScheduleOptimizationRequest): Promise<{ success: boolean; optimizedShifts?: Shift[]; metrics?: any; error?: string }> {
    try {
      const response = await this.makeRequest<{ shifts: Shift[]; metrics: any }>('/api/v1/schedules/optimize', {
        method: 'POST',
        body: JSON.stringify(request),
      });

      return {
        success: true,
        optimizedShifts: response.shifts,
        metrics: response.metrics
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to optimize schedule'
      };
    }
  }

  // Get schedule coverage metrics
  async getCoverageMetrics(startDate: string, endDate: string): Promise<{ success: boolean; metrics?: any; error?: string }> {
    try {
      const params = new URLSearchParams({
        start_date: startDate,
        end_date: endDate
      });

      const response = await this.makeRequest<{ metrics: any }>(`/api/v1/schedules/coverage?${params}`);
      
      return {
        success: true,
        metrics: response.metrics
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch coverage metrics'
      };
    }
  }
}

// Export singleton instance
const realScheduleService = new RealScheduleService();
export default realScheduleService;

// Export types for use in components
export type {
  Employee,
  Shift,
  ScheduleRequest,
  ScheduleResponse,
  CreateShiftRequest,
  UpdateShiftRequest,
  ScheduleOptimizationRequest
};