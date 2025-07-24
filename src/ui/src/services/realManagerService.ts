// Real Manager Service - NO MOCK FALLBACKS
// This service makes REAL API calls to manager dashboard endpoints

import { realAuthService } from './realAuthService';

interface DashboardMetrics {
  teamSize: number;
  activeEmployees: number;
  onVacation: number;
  onSickLeave: number;
  pendingRequests: number;
  approvedThisMonth: number;
  rejectedThisMonth: number;
  avgResponseTime: string;
}

interface PendingRequest {
  id: string; // UUID string
  employeeId: string; // UUID string
  employeeName: string;
  type: 'vacation' | 'sick_leave' | 'shift_swap' | 'overtime';
  startDate: string;
  endDate: string;
  reason: string;
  status: 'pending';
  submittedDate: string;
  coverageImpact?: number;
}

interface TeamMemberStatus {
  id: string; // UUID string
  name: string;
  status: 'working' | 'vacation' | 'sick' | 'off';
  currentShift?: string;
  nextShift?: string;
}

interface ManagerDashboardResponse {
  managerId: number; // Integer ID
  managerName: string;
  metrics: DashboardMetrics;
  pendingRequests: PendingRequest[];
  teamStatus: TeamMemberStatus[];
  lastUpdated: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001';

class RealManagerService {
  /**
   * Get manager dashboard data - NO MOCK FALLBACK
   */
  async getManagerDashboard(managerId: number): Promise<ManagerDashboardResponse> {
    const token = realAuthService.getAuthToken();
    if (!token) {
      throw new Error('Authentication required');
    }

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/managers/${managerId}/dashboard`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to fetch manager dashboard: ${errorText || response.statusText}`);
      }

      let data;
      try {
        // Try to parse as JSON first
        data = await response.json();
      } catch (jsonError) {
        // If JSON parsing fails, try parsing the text as JSON
        const text = await response.text();
        data = JSON.parse(text);
      }
      
      console.log('[MANAGER SERVICE] Raw API response:', data);
      
      // Transform the API response to match our interface
      // Use bracket notation to handle spaced JSON keys
      const transformedData: ManagerDashboardResponse = {
        managerId: data['manager_id'] || data.manager_id,
        managerName: (data.team && data.team.name) ? `${data.team.name} Manager` : 'Manager',
        metrics: {
          teamSize: (data.team && data.team['total_members']) ? data.team['total_members'] : 0,
          activeEmployees: (data['today_metrics'] && data['today_metrics']['scheduled_employees']) ? data['today_metrics']['scheduled_employees'] : 0,
          onVacation: 0, // Calculate from team members if needed
          onSickLeave: 0, // Calculate from team members if needed
          pendingRequests: (data['today_metrics'] && data['today_metrics']['pending_requests']) ? data['today_metrics']['pending_requests'] : 0,
          approvedThisMonth: 0, // Not available in this API
          rejectedThisMonth: 0, // Not available in this API
          avgResponseTime: '0h' // Not available in this API
        },
        pendingRequests: [], // Would need to fetch separately
        teamStatus: (data['team_members'] || []).map((member: any) => ({
          id: member.id,
          name: member.name,
          status: member['has_schedule_today'] ? 'working' : 'off'
        })),
        lastUpdated: data['generated_at'] || data.generated_at || new Date().toISOString()
      };
      
      console.log('[MANAGER SERVICE] Transformed data:', transformedData);
      return transformedData;
    } catch (error) {
      console.error('Manager dashboard error:', error);
      throw error;
    }
  }

  /**
   * Approve a request - NO MOCK FALLBACK
   */
  async approveRequest(requestId: string, comment?: string): Promise<{ success: boolean; message: string }> {
    const token = realAuthService.getAuthToken();
    if (!token) {
      throw new Error('Authentication required');
    }

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/requests/${requestId}/approve`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          comment: comment || '',
          approvedAt: new Date().toISOString(),
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to approve request: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return { success: true, message: data.message || 'Request approved successfully' };
    } catch (error) {
      console.error('Approve request error:', error);
      throw error;
    }
  }

  /**
   * Reject a request - NO MOCK FALLBACK
   */
  async rejectRequest(requestId: string, reason: string): Promise<{ success: boolean; message: string }> {
    const token = realAuthService.getAuthToken();
    if (!token) {
      throw new Error('Authentication required');
    }

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/requests/${requestId}/reject`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          reason,
          rejectedAt: new Date().toISOString(),
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to reject request: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return { success: true, message: data.message || 'Request rejected successfully' };
    } catch (error) {
      console.error('Reject request error:', error);
      throw error;
    }
  }
}

// Export singleton instance
export const realManagerService = new RealManagerService();

// Export type definitions
export type { DashboardMetrics, PendingRequest, TeamMemberStatus, ManagerDashboardResponse };