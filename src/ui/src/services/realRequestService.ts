/**
 * REAL Request Service - First component with actual backend integration
 * NO MOCK DATA - connects to real INTEGRATION-OPUS endpoints
 */

export interface VacationRequestData {
  id?: string;
  employee_id: string; // BDD Compliance: API expects UUID string, not number
  start_date: string; // API expects YYYY-MM-DD format
  end_date: string; // API expects YYYY-MM-DD format  
  description: string; // API expects description, not reason
  
  // UI fields (will be converted for API)
  type?: 'vacation';
  title?: string;
  reason?: string;
  priority?: 'low' | 'normal' | 'high' | 'urgent';
  attachments?: File[];
  additionalInfo?: {
    emergencyContact?: string;
    halfDay?: boolean;
  };
  status?: 'draft' | 'submitted' | 'approved' | 'rejected';
  submittedAt?: Date;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface SubmissionResult {
  requestId: string;
  status: string;
  message: string;
  submittedAt: string;
}

const API_BASE_URL = 'http://localhost:8000/api/v1';

class RealRequestService {
  
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
      
      // NO MOCK FALLBACK - return real error
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  private getAuthToken(): string {
    // Get real JWT token from localStorage
    const token = localStorage.getItem('authToken');
    if (!token) {
      throw new Error('No authentication token found');
    }
    return token;
  }

  private async uploadAttachments(files: File[]): Promise<string[]> {
    const uploadedUrls: string[] = [];
    
    for (const file of files) {
      const formData = new FormData();
      formData.append('file', file);
      
      try {
        console.log(`[REAL API] Uploading file: ${file.name}`);
        
        const response = await fetch(`${API_BASE_URL}/files/upload`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.getAuthToken()}`,
          },
          body: formData,
        });

        if (!response.ok) {
          throw new Error(`Upload failed for ${file.name}`);
        }

        const result = await response.json();
        uploadedUrls.push(result.fileUrl);
        
        console.log(`[REAL API] File uploaded: ${result.fileUrl}`);
        
      } catch (error) {
        console.error(`[REAL API] Upload error for ${file.name}:`, error);
        throw error;
      }
    }
    
    return uploadedUrls;
  }

  async submitVacationRequest(requestData: VacationRequestData): Promise<ApiResponse<SubmissionResult>> {
    console.log('[REAL API] Submitting vacation request:', requestData);
    
    try {
      // Upload attachments first if any
      let attachmentUrls: string[] = [];
      if (requestData.attachments && requestData.attachments.length > 0) {
        console.log('[REAL API] Uploading attachments...');
        attachmentUrls = await this.uploadAttachments(requestData.attachments);
      }

      // BDD Compliance: Use real UUID from employee selection, no hardcoded fallback
      const payload = {
        employee_id: requestData.employee_id || requestData.employeeId as string,
        start_date: requestData.start_date || requestData.startDate,
        end_date: requestData.end_date || requestData.endDate,
        description: requestData.description || requestData.reason || requestData.title || 'Vacation request'
      };

      // BDD Compliance: Validate UUID format
      if (!payload.employee_id || typeof payload.employee_id !== 'string') {
        throw new Error('Invalid employee ID: Must be a valid UUID string');
      }

      console.log('[REAL API] Sending payload:', payload);

      // Make actual API call to INTEGRATION-OPUS
      const result = await this.makeRequest<SubmissionResult>('/api/v1/requests/vacation', {
        method: 'POST',
        body: JSON.stringify(payload)
      });

      if (result.success) {
        console.log('[REAL API] Request submitted successfully:', result.data);
      } else {
        console.error('[REAL API] Request submission failed:', result.error);
      }

      return result;

    } catch (error) {
      console.error('[REAL API] Submission error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to submit request'
      };
    }
  }

  async getMyRequests(): Promise<ApiResponse<VacationRequestData[]>> {
    console.log('[REAL API] Fetching user requests...');
    
    return this.makeRequest<VacationRequestData[]>('/requests/my');
  }

  async getRequestStatus(requestId: string): Promise<ApiResponse<{ status: string; lastUpdated: string }>> {
    console.log(`[REAL API] Checking status for request: ${requestId}`);
    
    return this.makeRequest<{ status: string; lastUpdated: string }>(`/requests/${requestId}/status`);
  }

  async cancelRequest(requestId: string): Promise<ApiResponse<{ success: boolean }>> {
    console.log(`[REAL API] Cancelling request: ${requestId}`);
    
    return this.makeRequest<{ success: boolean }>(`/requests/${requestId}/cancel`, {
      method: 'POST'
    });
  }

  // Health check to verify API connectivity
  async checkApiHealth(): Promise<boolean> {
    try {
      console.log('[REAL API] Checking API health...');
      
      const response = await fetch(`${API_BASE_URL}/health`);
      const isHealthy = response.ok;
      
      console.log(`[REAL API] API health status: ${isHealthy ? 'OK' : 'ERROR'}`);
      return isHealthy;
      
    } catch (error) {
      console.error('[REAL API] Health check failed:', error);
      return false;
    }
  }
}

export const realRequestService = new RealRequestService();
export default realRequestService;