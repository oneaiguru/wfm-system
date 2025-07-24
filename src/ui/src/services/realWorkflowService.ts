/**
 * Real Workflow Service - Connects to SPEC-13 Workflow APIs
 * NO MOCK DATA - Production-ready workflow management
 */

import { realAuthService } from './realAuthService';

export interface WorkflowInstance {
  instance_id: string;
  template_id: string;
  template_name: string;
  request_id: string;
  request_type: string;
  current_state: string;
  status: 'active' | 'completed' | 'cancelled';
  initiated_by: string;
  initiated_at: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  assignee?: {
    type: 'manager' | 'system' | 'employee';
    username?: string;
    process?: string;
    assigned_at: string;
  };
  request_summary: any;
  time_in_current_state?: string;
  total_duration?: string;
  completed_by?: string;
  completed_at?: string;
  due_date?: string;
}

export interface WorkflowResponse {
  workflow_instances: WorkflowInstance[];
  summary: {
    total_instances: number;
    active_instances: number;
    completed_instances: number;
    overdue_instances: number;
  };
  my_assignments: WorkflowInstance[];
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

class RealWorkflowService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[WORKFLOW API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const token = realAuthService.getAuthToken();
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token ? `Bearer ${token}` : '',
          ...options.headers,
        },
        ...options,
      });

      if (!response.ok) {
        throw new Error(`API request failed: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      console.log(`[WORKFLOW API] Response from ${endpoint}:`, data);
      
      return {
        success: true,
        data: data
      };

    } catch (error) {
      console.error(`[WORKFLOW API] Error calling ${endpoint}:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  async getWorkflowInstances(): Promise<ApiResponse<WorkflowResponse>> {
    return this.makeRequest<WorkflowResponse>('/workflows/instances');
  }

  async getMyWorkflowTasks(): Promise<ApiResponse<WorkflowResponse>> {
    return this.makeRequest<WorkflowResponse>('/workflows/my-tasks');
  }

  async checkApiHealth(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      return response.ok;
    } catch (error) {
      console.error('[WORKFLOW API] Health check failed:', error);
      return false;
    }
  }
}

export const realWorkflowService = new RealWorkflowService();
export default realWorkflowService;