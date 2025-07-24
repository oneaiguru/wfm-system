// Real Shift Service - NO MOCK FALLBACKS
// This service makes REAL API calls to shift management endpoints

import { realAuthService } from './realAuthService';

interface Shift {
  id: number;
  date: string;
  startTime: string;
  endTime: string;
  employeeId: number;
  employeeName: string;
  department: string;
  type: 'regular' | 'overtime' | 'holiday';
}

interface ShiftTradeRequest {
  myShiftId: number;
  requestedShiftId: number;
  reason: string;
  requestDate?: string;
}

interface ShiftTradeResponse {
  id: number;
  status: 'pending' | 'approved' | 'rejected';
  myShift: Shift;
  requestedShift: Shift;
  reason: string;
  requestDate: string;
  responseDate?: string;
  managerComment?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001';

class RealShiftService {
  /**
   * Request a shift trade - NO MOCK FALLBACK
   */
  async requestShiftTrade(request: ShiftTradeRequest): Promise<ShiftTradeResponse> {
    const token = realAuthService.getAuthToken();
    if (!token) {
      throw new Error('Authentication required');
    }

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/shifts/request-trade`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          ...request,
          requestDate: request.requestDate || new Date().toISOString(),
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to request shift trade: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Shift trade request error:', error);
      throw error;
    }
  }

  /**
   * Get employee shifts - NO MOCK FALLBACK
   */
  async getEmployeeShifts(employeeId: number, startDate?: string, endDate?: string): Promise<Shift[]> {
    const token = realAuthService.getAuthToken();
    if (!token) {
      throw new Error('Authentication required');
    }

    try {
      const params = new URLSearchParams();
      if (startDate) params.append('start_date', startDate);
      if (endDate) params.append('end_date', endDate);

      const response = await fetch(`${API_BASE_URL}/api/v1/employees/${employeeId}/shifts?${params}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to fetch employee shifts: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return data.shifts || [];
    } catch (error) {
      console.error('Employee shifts error:', error);
      throw error;
    }
  }

  /**
   * Get available shifts for trading - NO MOCK FALLBACK
   */
  async getAvailableShifts(employeeId: number): Promise<Shift[]> {
    const token = realAuthService.getAuthToken();
    if (!token) {
      throw new Error('Authentication required');
    }

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/shifts/available-for-trade?employee_id=${employeeId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to fetch available shifts: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return data.shifts || [];
    } catch (error) {
      console.error('Available shifts error:', error);
      throw error;
    }
  }
}

// Export singleton instance
export const realShiftService = new RealShiftService();

// Export type definitions
export type { Shift, ShiftTradeRequest, ShiftTradeResponse };