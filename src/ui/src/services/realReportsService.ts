/**
 * REAL Reports Service - NO MOCK DATA
 * Connects to actual INTEGRATION-OPUS endpoints for reports & analytics
 */

import { realAuthService } from './realAuthService';

export interface ReportListItem {
  report_id: string;
  name: string;
  type: 'schedule-adherence' | 'payroll' | 'forecast-accuracy' | 'kpi-dashboard' | 'absence-analysis';
  description: string;
  last_generated: string;
  status: 'completed' | 'running' | 'failed';
  format: 'excel' | 'pdf' | 'csv' | 'json';
  size_mb?: number;
}

export interface ScheduleAdherenceReport {
  report_id: string;
  period_start: string;
  period_end: string;
  department: string;
  detail_level: 'fifteen-minute' | 'hourly' | 'daily' | 'weekly' | 'monthly';
  average_adherence: number;
  total_scheduled_hours: number;
  total_actual_hours: number;
  total_deviation_hours: number;
  employees: Array<{
    employee_id: string;
    employee_name: string;
    scheduled_hours: number;
    actual_hours: number;
    adherence_percentage: number;
    deviation_hours: number;
  }>;
  generated_at: string;
}

export interface ForecastAccuracyReport {
  report_id: string;
  period_start: string;
  period_end: string;
  overall_metrics: {
    mape: number;
    wape: number;
    mfa: number;
    wfa: number;
    bias: number;
    tracking_signal: number;
  };
  interval_analysis: Array<{
    time_interval: string;
    forecasted: number;
    actual: number;
    accuracy: number;
    pattern: string;
  }>;
  daily_analysis: Array<{
    date: string;
    day_of_week: string;
    forecasted_volume: number;
    actual_volume: number;
    accuracy: number;
  }>;
  generated_at: string;
}

export interface KPIDashboard {
  dashboard_id: string;
  service_level: KPIMetric;
  answer_time: KPIMetric;
  occupancy: KPIMetric;
  utilization: KPIMetric;
  customer_satisfaction: KPIMetric;
  first_call_resolution: KPIMetric;
  adherence: KPIMetric;
  shrinkage: KPIMetric;
  forecast_accuracy: KPIMetric;
  forecast_bias: KPIMetric;
  cost_per_contact: KPIMetric;
  overtime_percentage: KPIMetric;
  last_refresh: string;
}

export interface KPIMetric {
  metric_name: string;
  current_value: number;
  target_value: number;
  unit: string;
  status: 'on_target' | 'warning' | 'critical';
  trend: 'up' | 'down' | 'stable';
  last_updated: string;
}

export interface RealtimeMetrics {
  timestamp: string;
  current_metrics: {
    staffing_percentage: number;
    service_level_80_20: number;
    average_queue_time: number;
    active_agents: number;
    calls_in_queue: number;
  };
  system_health: {
    integration_status: string;
    database_status: string;
    api_response_time: number;
  };
  active_alerts: Array<{
    type: string;
    condition: string;
    notification: string;
    severity: 'info' | 'warning' | 'critical' | 'emergency';
  }>;
  update_frequency: {
    staffing: string;
    service_levels: string;
    queue_status: string;
    system_health: string;
  };
}

export interface ExportJob {
  job_id: string;
  report_type: string;
  format: 'excel' | 'pdf' | 'csv' | 'json';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  created_at: string;
  completed_at?: string;
  file_url?: string;
  file_size_mb?: number;
  error_message?: string;
  parameters: Record<string, any>;
}

export interface ExportRequest {
  report_type: 'schedule-adherence' | 'forecast-accuracy' | 'payroll' | 'kpi-dashboard' | 'real-time';
  format: 'excel' | 'pdf' | 'csv' | 'json';
  parameters: Record<string, any>;
  email_recipient?: string;
  include_charts?: boolean;
  compress_file?: boolean;
}

export interface ScheduledReport {
  schedule_id: string;
  name: string;
  description?: string;
  report_type: 'schedule-adherence' | 'forecast-accuracy' | 'payroll' | 'kpi-dashboard' | 'real-time';
  format: 'excel' | 'pdf' | 'csv' | 'json';
  schedule_pattern: 'daily' | 'weekly' | 'monthly' | 'quarterly';
  schedule_time: string; // HH:MM format
  schedule_day?: number; // 1-31 for monthly, 0-6 for weekly (0=Sunday)
  is_active: boolean;
  parameters: Record<string, any>;
  email_recipients: string[];
  last_run?: string;
  next_run?: string;
  created_at: string;
  created_by: string;
  run_count: number;
  failure_count: number;
}

export interface CreateScheduledReportRequest {
  name: string;
  description?: string;
  report_type: 'schedule-adherence' | 'forecast-accuracy' | 'payroll' | 'kpi-dashboard' | 'real-time';
  format: 'excel' | 'pdf' | 'csv' | 'json';
  schedule_pattern: 'daily' | 'weekly' | 'monthly' | 'quarterly';
  schedule_time: string;
  schedule_day?: number;
  parameters: Record<string, any>;
  email_recipients: string[];
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

class RealReportsService {
  
  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    try {
      console.log(`[REAL REPORTS API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const token = realAuthService.getAuthToken();
      if (!token) {
        throw new Error('No authentication token found. Please log in.');
      }
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
          ...options.headers,
        },
        ...options,
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      return { success: true, data: data as T };

    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error('[REAL REPORTS API] Error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred'
      };
    }
  }

  /**
   * Get list of available reports
   */
  async getReportsList(): Promise<ApiResponse<ReportListItem[]>> {
    console.log('[REAL REPORTS API] Fetching reports list');
    
    try {
      const response = await fetch(`${API_BASE_URL}/reports/list`, {
        headers: {
          'Content-Type': 'application/json',
          // No auth required for this endpoint
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      
      // Map API response to our interface
      const reports: ReportListItem[] = data.map((item: any) => ({
        report_id: item.report_id,
        name: item.title || item.report_type,
        type: item.report_type || 'kpi-dashboard',
        description: item.description,
        last_generated: item.generated_at,
        status: item.status === 'ready' ? 'completed' : item.status,
        format: item.download_url?.includes('excel') ? 'excel' : 'json',
        size_mb: item.file_size ? item.file_size / 1024 / 1024 : undefined
      }));
      
      return { success: true, data: reports };
    } catch (error) {
      console.error('[REAL REPORTS API] Failed to fetch reports list:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch reports'
      };
    }
  }

  /**
   * Generate schedule adherence report
   */
  async generateScheduleAdherenceReport(params: {
    period_start: string;
    period_end: string;
    department?: string;
    detail_level?: 'fifteen-minute' | 'hourly' | 'daily' | 'weekly' | 'monthly';
    include_weekends?: boolean;
    show_exceptions?: boolean;
  }): Promise<ApiResponse<ScheduleAdherenceReport>> {
    console.log('[REAL REPORTS API] Generating schedule adherence report:', params);
    
    return this.makeRequest<ScheduleAdherenceReport>('/reports/schedule-adherence', {
      method: 'POST',
      body: JSON.stringify({
        period_start: params.period_start,
        period_end: params.period_end,
        department: params.department || 'Technical Support',
        detail_level: params.detail_level || 'fifteen-minute',
        include_weekends: params.include_weekends ?? true,
        show_exceptions: params.show_exceptions ?? true
      })
    });
  }

  /**
   * Get forecast accuracy analysis
   */
  async getForecastAccuracyReport(params: {
    period_start: string;
    period_end: string;
    service_group?: string;
  }): Promise<ApiResponse<ForecastAccuracyReport>> {
    console.log('[REAL REPORTS API] Fetching forecast accuracy report:', params);
    
    const queryParams = new URLSearchParams({
      period_start: params.period_start,
      period_end: params.period_end
    });
    
    if (params.service_group) {
      queryParams.append('service_group', params.service_group);
    }
    
    return this.makeRequest<ForecastAccuracyReport>(`/reports/forecast-accuracy?${queryParams}`);
  }

  /**
   * Get KPI dashboard
   */
  async getKPIDashboard(): Promise<ApiResponse<KPIDashboard>> {
    console.log('[REAL REPORTS API] Fetching KPI dashboard');
    
    return this.makeRequest<KPIDashboard>('/reports/kpi-dashboard');
  }

  /**
   * Get real-time operational metrics
   */
  async getRealtimeMetrics(): Promise<ApiResponse<RealtimeMetrics>> {
    console.log('[REAL REPORTS API] Fetching real-time metrics');
    
    return this.makeRequest<RealtimeMetrics>('/reports/real-time');
  }

  /**
   * Create export job
   */
  async createExportJob(exportRequest: ExportRequest): Promise<ApiResponse<ExportJob>> {
    console.log('[REAL REPORTS API] Creating export job:', exportRequest);
    
    return this.makeRequest<ExportJob>('/exports/create', {
      method: 'POST',
      body: JSON.stringify(exportRequest)
    });
  }

  /**
   * Get export job status
   */
  async getExportJobStatus(jobId: string): Promise<ApiResponse<ExportJob>> {
    console.log('[REAL REPORTS API] Getting export job status:', jobId);
    
    return this.makeRequest<ExportJob>(`/exports/status/${jobId}`);
  }

  /**
   * Get list of export jobs
   */
  async getExportJobs(limit: number = 20): Promise<ApiResponse<ExportJob[]>> {
    console.log('[REAL REPORTS API] Fetching export jobs');
    
    return this.makeRequest<ExportJob[]>(`/exports/jobs?limit=${limit}`);
  }

  /**
   * Cancel export job
   */
  async cancelExportJob(jobId: string): Promise<ApiResponse<{ cancelled: boolean }>> {
    console.log('[REAL REPORTS API] Cancelling export job:', jobId);
    
    return this.makeRequest<{ cancelled: boolean }>(`/exports/cancel/${jobId}`, {
      method: 'POST'
    });
  }

  /**
   * Download export file
   */
  async downloadExportFile(jobId: string): Promise<void> {
    try {
      const token = realAuthService.getAuthToken();
      if (!token) {
        throw new Error('No authentication token found');
      }

      const response = await fetch(`${API_BASE_URL}/exports/download/${jobId}`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`Download failed: ${response.statusText}`);
      }

      // Get filename from Content-Disposition header or use default
      const contentDisposition = response.headers.get('Content-Disposition');
      let filename = `export_${jobId}.xlsx`;
      if (contentDisposition) {
        const filenameMatch = contentDisposition.match(/filename="(.+)"/);
        if (filenameMatch) {
          filename = filenameMatch[1];
        }
      }

      // Create download
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);

      console.log('[REAL REPORTS API] File downloaded:', filename);
    } catch (error) {
      console.error('[REAL REPORTS API] Download error:', error);
      throw error;
    }
  }

  /**
   * Get all scheduled reports
   */
  async getScheduledReports(): Promise<ApiResponse<ScheduledReport[]>> {
    console.log('[REAL REPORTS API] Fetching scheduled reports');
    
    return this.makeRequest<ScheduledReport[]>('/reports/scheduled');
  }

  /**
   * Create new scheduled report
   */
  async createScheduledReport(request: CreateScheduledReportRequest): Promise<ApiResponse<ScheduledReport>> {
    console.log('[REAL REPORTS API] Creating scheduled report:', request);
    
    return this.makeRequest<ScheduledReport>('/reports/scheduled', {
      method: 'POST',
      body: JSON.stringify(request)
    });
  }

  /**
   * Update scheduled report
   */
  async updateScheduledReport(scheduleId: string, updates: Partial<CreateScheduledReportRequest>): Promise<ApiResponse<ScheduledReport>> {
    console.log('[REAL REPORTS API] Updating scheduled report:', scheduleId, updates);
    
    return this.makeRequest<ScheduledReport>(`/reports/scheduled/${scheduleId}`, {
      method: 'PUT',
      body: JSON.stringify(updates)
    });
  }

  /**
   * Delete scheduled report
   */
  async deleteScheduledReport(scheduleId: string): Promise<ApiResponse<{ deleted: boolean }>> {
    console.log('[REAL REPORTS API] Deleting scheduled report:', scheduleId);
    
    return this.makeRequest<{ deleted: boolean }>(`/reports/scheduled/${scheduleId}`, {
      method: 'DELETE'
    });
  }

  /**
   * Toggle scheduled report active status
   */
  async toggleScheduledReport(scheduleId: string, isActive: boolean): Promise<ApiResponse<ScheduledReport>> {
    console.log('[REAL REPORTS API] Toggling scheduled report:', scheduleId, isActive);
    
    return this.makeRequest<ScheduledReport>(`/reports/scheduled/${scheduleId}/toggle`, {
      method: 'POST',
      body: JSON.stringify({ is_active: isActive })
    });
  }

  /**
   * Run scheduled report immediately
   */
  async runScheduledReportNow(scheduleId: string): Promise<ApiResponse<ExportJob>> {
    console.log('[REAL REPORTS API] Running scheduled report now:', scheduleId);
    
    return this.makeRequest<ExportJob>(`/reports/scheduled/${scheduleId}/run`, {
      method: 'POST'
    });
  }

  /**
   * Check API health before making reports requests
   */
  async checkApiHealth(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      return response.ok;
    } catch (error) {
      console.error('[REAL REPORTS API] Health check failed:', error);
      return false;
    }
  }
}

export const realReportsService = new RealReportsService();
export default realReportsService;