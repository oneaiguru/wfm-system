/**
 * REAL Russian Request Service - SPEC-08 Integration
 * NO MOCK DATA - connects to real INTEGRATION-OPUS Russian endpoints
 * Supports: больничный, отгул, внеочередной отпуск, обмен смен
 */

export interface RussianRequestData {
  id?: string;
  employee_id: string; // BDD Compliance: API expects UUID string
  type: 'больничный' | 'отгул' | 'внеочередной отпуск' | 'обмен смен';
  start_date: string; // API expects YYYY-MM-DD format
  end_date: string; // API expects YYYY-MM-DD format
  reason: string; // причина
  description?: string; // дополнительная информация
  
  // Type-specific fields
  medical_certificate_number?: string; // для больничного
  medical_certificate_url?: string; // uploaded file URL
  emergency_contact?: string; // для больничного
  overtime_balance?: number; // для отгула
  replacement_employee?: string; // для отгула
  target_shift_id?: string; // для обмена смен
  urgency_level?: 'normal' | 'urgent' | 'emergency'; // для внеочередного отпуска
  
  // Calculated fields
  working_days_count?: number;
  half_day?: boolean;
  
  // Status and workflow
  status?: 'ожидает_подтверждения' | 'на_рассмотрении' | 'одобрено' | 'отклонено' | 'отменено';
  approval_workflow?: string;
  created_at?: string;
  submitted_at?: string;
}

export interface RussianApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  status_ru?: string; // Russian status message
}

export interface RussianSubmissionResult {
  request_id: string;
  status: string;
  status_ru: string; // Russian status
  message: string;
  message_ru: string; // Russian message
  submitted_at: string;
  approval_required: boolean;
  zup_export_queued?: boolean; // 1C ZUP integration status
}

export interface ValidationResult {
  is_valid: boolean;
  errors: string[];
  errors_ru: string[]; // Russian error messages
  warnings?: string[];
  warnings_ru?: string[]; // Russian warnings
}

const API_BASE_URL = 'http://localhost:8001/api/v1';

class RealRussianRequestService {
  
  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<RussianApiResponse<T>> {
    try {
      console.log(`[RUSSIAN API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
          'Accept-Language': 'ru-RU',
          ...options.headers,
        },
        ...options,
      });

      console.log(`[RUSSIAN API] Response status: ${response.status}`);

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[RUSSIAN API] Error response: ${errorText}`);
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      console.log(`[RUSSIAN API] Success response:`, data);
      
      return {
        success: true,
        data: data as T
      };

    } catch (error) {
      console.error(`[RUSSIAN API] Request failed:`, error);
      
      // NO MOCK FALLBACK - return real error
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Произошла неизвестная ошибка'
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

  private async uploadMedicalCertificate(file: File): Promise<string> {
    const formData = new FormData();
    formData.append('medical_certificate', file);
    
    try {
      console.log(`[RUSSIAN API] Uploading medical certificate: ${file.name}`);
      
      const response = await fetch(`${API_BASE_URL}/files/medical-certificates/upload`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.getAuthToken()}`,
        },
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`Ошибка загрузки файла: ${file.name}`);
      }

      const result = await response.json();
      console.log(`[RUSSIAN API] Medical certificate uploaded: ${result.fileUrl}`);
      
      return result.fileUrl;
      
    } catch (error) {
      console.error(`[RUSSIAN API] Upload error for ${file.name}:`, error);
      throw error;
    }
  }

  // SPEC-08: больничный (Sick Leave) Request
  async submitSickLeaveRequest(requestData: RussianRequestData, medicalCertificate?: File): Promise<RussianApiResponse<RussianSubmissionResult>> {
    console.log('[RUSSIAN API] Submitting больничный request:', requestData);
    
    try {
      // Upload medical certificate if provided
      let certificateUrl: string | undefined;
      if (medicalCertificate) {
        console.log('[RUSSIAN API] Uploading medical certificate...');
        certificateUrl = await this.uploadMedicalCertificate(medicalCertificate);
      }

      const payload = {
        employee_id: requestData.employee_id,
        start_date: requestData.start_date,
        end_date: requestData.end_date,
        reason: requestData.reason,
        description: requestData.description,
        medical_certificate_number: requestData.medical_certificate_number,
        medical_certificate_url: certificateUrl,
        emergency_contact: requestData.emergency_contact,
        working_days_count: requestData.working_days_count,
        half_day: requestData.half_day || false
      };

      console.log('[RUSSIAN API] Sending больничный payload:', payload);

      // Call SPEC-08 больничный endpoint
      const result = await this.makeRequest<RussianSubmissionResult>('/requests/bolnichny', {
        method: 'POST',
        body: JSON.stringify(payload)
      });

      if (result.success) {
        console.log('[RUSSIAN API] больничный submitted successfully:', result.data);
      }

      return result;

    } catch (error) {
      console.error('[RUSSIAN API] больничный submission error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Ошибка отправки больничного'
      };
    }
  }

  // SPEC-08: отгул (Time Off) Request  
  async submitTimeOffRequest(requestData: RussianRequestData): Promise<RussianApiResponse<RussianSubmissionResult>> {
    console.log('[RUSSIAN API] Submitting отгул request:', requestData);
    
    try {
      const payload = {
        employee_id: requestData.employee_id,
        start_date: requestData.start_date,
        end_date: requestData.end_date,
        reason: requestData.reason,
        description: requestData.description,
        overtime_balance: requestData.overtime_balance,
        replacement_employee: requestData.replacement_employee,
        working_days_count: requestData.working_days_count,
        half_day: requestData.half_day || false
      };

      console.log('[RUSSIAN API] Sending отгул payload:', payload);

      // Call SPEC-08 отгул endpoint
      const result = await this.makeRequest<RussianSubmissionResult>('/requests/otgul', {
        method: 'POST',
        body: JSON.stringify(payload)
      });

      if (result.success) {
        console.log('[RUSSIAN API] отгул submitted successfully:', result.data);
      }

      return result;

    } catch (error) {
      console.error('[RUSSIAN API] отгул submission error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Ошибка отправки отгула'
      };
    }
  }

  // SPEC-08: внеочередной отпуск (Unscheduled Vacation) Request
  async submitUnscheduledVacationRequest(requestData: RussianRequestData): Promise<RussianApiResponse<RussianSubmissionResult>> {
    console.log('[RUSSIAN API] Submitting внеочередной отпуск request:', requestData);
    
    try {
      const payload = {
        employee_id: requestData.employee_id,
        start_date: requestData.start_date,
        end_date: requestData.end_date,
        reason: requestData.reason,
        description: requestData.description,
        urgency_level: requestData.urgency_level || 'urgent',
        working_days_count: requestData.working_days_count,
        half_day: requestData.half_day || false
      };

      console.log('[RUSSIAN API] Sending внеочередной отпуск payload:', payload);

      // Call SPEC-08 внеочередной отпуск endpoint
      const result = await this.makeRequest<RussianSubmissionResult>('/requests/vneoherednoy-otpusk', {
        method: 'POST',
        body: JSON.stringify(payload)
      });

      if (result.success) {
        console.log('[RUSSIAN API] внеочередной отпуск submitted successfully:', result.data);
      }

      return result;

    } catch (error) {
      console.error('[RUSSIAN API] внеочередной отпуск submission error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Ошибка отправки внеочередного отпуска'
      };
    }
  }

  // SPEC-08: обмен смен (Shift Exchange) Request
  async submitShiftExchangeRequest(requestData: RussianRequestData): Promise<RussianApiResponse<RussianSubmissionResult>> {
    console.log('[RUSSIAN API] Submitting обмен смен request:', requestData);
    
    try {
      const payload = {
        employee_id: requestData.employee_id,
        current_shift_date: requestData.start_date,
        target_shift_id: requestData.target_shift_id,
        reason: requestData.reason,
        description: requestData.description
      };

      console.log('[RUSSIAN API] Sending обмен смен payload:', payload);

      // Call SPEC-08 shift exchange endpoint
      const result = await this.makeRequest<RussianSubmissionResult>('/requests/shift-exchange', {
        method: 'POST',
        body: JSON.stringify(payload)
      });

      if (result.success) {
        console.log('[RUSSIAN API] обмен смен submitted successfully:', result.data);
      }

      return result;

    } catch (error) {
      console.error('[RUSSIAN API] обмен смен submission error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Ошибка отправки запроса на обмен смен'
      };
    }
  }

  // Get request status with Russian labels
  async getRequestStatus(requestId: string): Promise<RussianApiResponse<{ status: string; status_ru: string; lastUpdated: string }>> {
    console.log(`[RUSSIAN API] Checking status for request: ${requestId}`);
    
    return this.makeRequest<{ status: string; status_ru: string; lastUpdated: string }>(`/requests/status?lang=ru&request_id=${requestId}`);
  }

  // Get user's Russian requests
  async getMyRussianRequests(): Promise<RussianApiResponse<RussianRequestData[]>> {
    console.log('[RUSSIAN API] Fetching user Russian requests...');
    
    return this.makeRequest<RussianRequestData[]>('/requests/my?lang=ru');
  }

  // Validate Russian request before submission
  async validateRussianRequest(requestData: RussianRequestData): Promise<RussianApiResponse<ValidationResult>> {
    console.log('[RUSSIAN API] Validating Russian request:', requestData);
    
    return this.makeRequest<ValidationResult>('/requests/validate?lang=ru', {
      method: 'POST',
      body: JSON.stringify(requestData)
    });
  }

  // Get Russian request types and policies
  async getRussianRequestTypes(): Promise<RussianApiResponse<{ types: string[]; policies: any }>> {
    console.log('[RUSSIAN API] Fetching Russian request types...');
    
    return this.makeRequest<{ types: string[]; policies: any }>('/requests/types?lang=ru');
  }

  // Health check for Russian API endpoints
  async checkRussianApiHealth(): Promise<boolean> {
    try {
      console.log('[RUSSIAN API] Checking Russian API health...');
      
      const response = await fetch(`${API_BASE_URL}/health/russian-requests`);
      const isHealthy = response.ok;
      
      console.log(`[RUSSIAN API] Russian API health status: ${isHealthy ? 'OK' : 'ERROR'}`);
      return isHealthy;
      
    } catch (error) {
      console.error('[RUSSIAN API] Health check failed:', error);
      return false;
    }
  }
}

export const realRussianRequestService = new RealRussianRequestService();
export default realRussianRequestService;