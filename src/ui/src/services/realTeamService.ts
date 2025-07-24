// Real Team Service - NO MOCK FALLBACKS
// This service makes REAL API calls to team-related endpoints

import { realAuthService } from './realAuthService';

interface TeamMember {
  id: number;
  name: string;
  role: string;
  department: string;
  status: 'working' | 'vacation' | 'sick' | 'off';
}

interface TeamCalendarEvent {
  id: number;
  employeeId: number;
  employeeName: string;
  type: 'shift' | 'vacation' | 'sick_leave' | 'training';
  date: string;
  startTime: string;
  endTime: string;
  status: string;
}

interface TeamCalendarResponse {
  teamId: number;
  teamName: string;
  period: {
    start: string;
    end: string;
  };
  members: TeamMember[];
  events: TeamCalendarEvent[];
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001';

class RealTeamService {
  /**
   * Get team calendar data - NO MOCK FALLBACK
   */
  async getTeamCalendar(teamId: number): Promise<TeamCalendarResponse> {
    const token = realAuthService.getAuthToken();
    if (!token) {
      throw new Error('Authentication required');
    }

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/teams/${teamId}/calendar`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to fetch team calendar: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Team calendar error:', error);
      throw error;
    }
  }

  /**
   * Get team members - NO MOCK FALLBACK
   */
  async getTeamMembers(teamId: number): Promise<TeamMember[]> {
    const token = realAuthService.getAuthToken();
    if (!token) {
      throw new Error('Authentication required');
    }

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/teams/${teamId}/members`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to fetch team members: ${errorText || response.statusText}`);
      }

      const data = await response.json();
      return data.members || [];
    } catch (error) {
      console.error('Team members error:', error);
      throw error;
    }
  }
}

// Export singleton instance
export const realTeamService = new RealTeamService();

// Export type definitions
export type { TeamMember, TeamCalendarEvent, TeamCalendarResponse };