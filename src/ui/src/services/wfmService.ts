import apiClient from './apiClient';
import { ForecastData, PeakAnalysisData } from '@/types/ChartTypes';
import { OptimizationParams, OptimizationResult } from '@/types/MultiSkillTypes';

interface HistoricalDataUploadResponse {
  id: string;
  fileName: string;
  rowCount: number;
  columns: string[];
  status: 'processing' | 'completed' | 'failed';
}

interface ForecastRequest {
  dataId: string;
  algorithm: 'ARIMA' | 'Linear Regression' | 'Moving Average' | 'Ensemble';
  horizon: number;
  confidence: number;
}

interface ErlangCRequest {
  arrival_rate: number;
  service_time: number;
  agents: number;
  target_service_level?: number;
}

interface ErlangCResponse {
  source: string;
  result: {
    utilization: number;
    probability_wait: number;
    average_wait_time: number;
    service_level: number;
    queue_length: number;
    optimal_agents?: number;
  };
  status: string;
}

interface AlgorithmInfo {
  name: string;
  module: string;
  status: string;
  features: string[];
}

interface PersonnelCalculation {
  peakRequirement: number;
  averageRequirement: number;
  totalFTE: number;
  parameters: {
    avgHandleTime: number;
    serviceLevelTarget: number;
    shrinkage: number;
  };
}

class WFMService {
  // Historical Data Management (Argus compatibility endpoints)
  async uploadHistoricalData(file: File, onProgress?: (percent: number) => void): Promise<HistoricalDataUploadResponse> {
    return apiClient.upload<HistoricalDataUploadResponse>('/argus/historic/upload', file, onProgress);
  }

  async getHistoricalData(dataId: string): Promise<any> {
    return apiClient.get(`/argus/historic/${dataId}`);
  }

  // Algorithm Integration
  async getAvailableAlgorithms(): Promise<{ algorithms: AlgorithmInfo[]; status: string }> {
    try {
      return await apiClient.get('/integration/algorithms/available');
    } catch (error) {
      // Return mock data when API is not available
      return {
        algorithms: [
          {
            name: 'erlang_c_enhanced',
            module: 'src.algorithms.core.erlang_c_enhanced',
            status: 'active',
            features: ['service_level_corridors', 'enhanced_staffing', 'sub_100ms_performance']
          },
          {
            name: 'ml_ensemble',
            module: 'src.algorithms.ml.ml_ensemble',
            status: 'active',
            features: ['prophet', 'arima', 'lightgbm', '75%_mfa_accuracy']
          }
        ],
        status: 'mock_data'
      };
    }
  }

  async calculateErlangC(params: ErlangCRequest): Promise<ErlangCResponse> {
    return apiClient.post<ErlangCResponse>('/integration/algorithms/erlang-c/direct', params);
  }

  // Enhanced Erlang C endpoint (service layer)
  async calculateEnhancedErlangC(params: {
    service_id?: string;
    forecast_calls: number;
    avg_handle_time: number;
    service_level_target: number;
    target_wait_time: number;
    multi_channel?: {
      channels: string[];
      distribution: Record<string, number>;
    };
  }): Promise<any> {
    return apiClient.post('/algorithms/erlang-c/calculate', params);
  }

  // Forecasting
  async createForecast(request: ForecastRequest): Promise<ForecastData> {
    return apiClient.post<ForecastData>('/algorithms/forecast/create', request);
  }

  async getForecast(forecastId: string): Promise<ForecastData> {
    return apiClient.get<ForecastData>(`/algorithms/forecast/${forecastId}`);
  }

  // Peak Analysis
  async analyzePeaks(dataId: string): Promise<PeakAnalysisData> {
    return apiClient.post<PeakAnalysisData>('/algorithms/erlang-c/multi-skill', { 
      data_id: dataId,
      analysis_type: 'peak_detection' 
    });
  }

  // Personnel Calculation (Argus endpoint)
  async calculatePersonnel(params: {
    forecastId?: string;
    callVolume: number;
    avgHandleTime: number;
    serviceLevelTarget: number;
    shrinkage: number;
  }): Promise<PersonnelCalculation> {
    // First calculate using Erlang C
    const erlangResult = await this.calculateErlangC({
      arrival_rate: params.callVolume,
      service_time: params.avgHandleTime / 60, // Convert seconds to minutes
      agents: Math.ceil(params.callVolume * params.avgHandleTime / 3600), // Initial estimate
      target_service_level: params.serviceLevelTarget / 100
    });

    // Apply shrinkage
    const shrinkageFactor = 1 + (params.shrinkage / 100);
    
    return {
      peakRequirement: Math.ceil(erlangResult.result.optimal_agents || 0),
      averageRequirement: Math.ceil((erlangResult.result.optimal_agents || 0) * 0.75),
      totalFTE: Math.ceil((erlangResult.result.optimal_agents || 0) * shrinkageFactor),
      parameters: {
        avgHandleTime: params.avgHandleTime,
        serviceLevelTarget: params.serviceLevelTarget,
        shrinkage: params.shrinkage
      }
    };
  }

  // Workflow Management
  async saveWorkflowState(tabId: string, data: any): Promise<{ id: string; status: string }> {
    return apiClient.post('/workflow/validate/state', { tabId, data });
  }

  async getWorkflowState(workflowId: string): Promise<any> {
    return apiClient.get(`/workflow/validate/state/${workflowId}`);
  }

  // Status and Health
  async getSystemStatus(): Promise<{
    status: 'healthy' | 'degraded' | 'down';
    services: Record<string, boolean>;
    timestamp: string;
  }> {
    return apiClient.get('/argus/ccwfm/status');
  }

  // Test integration
  async testIntegration(): Promise<any> {
    return apiClient.get('/integration/algorithms/test-integration');
  }

  // Multi-Skill Optimization
  async optimizeMultiSkill(params: OptimizationParams): Promise<{ data: OptimizationResult }> {
    return apiClient.post('/algorithms/multi-skill/optimize', params);
  }

  async getMultiSkillAssignments(params: {
    serviceId?: string;
    skillGroups?: string[];
    includeMetrics?: boolean;
  }): Promise<any> {
    return apiClient.get('/algorithms/multi-skill/assignments', { params });
  }

  async simulateMultiSkillScenario(params: {
    scenario: 'project_i' | 'custom';
    queueCount?: number;
    employeeCount?: number;
    targetAccuracy?: number;
  }): Promise<any> {
    return apiClient.post('/algorithms/multi-skill/simulate', params);
  }

  async compareWithArgus(params: {
    currentAssignments: any[];
    queueCount: number;
    complexity: 'low' | 'medium' | 'high';
  }): Promise<{
    ourAccuracy: number;
    argusAccuracy: number;
    improvement: number;
    costSavings: number;
  }> {
    return apiClient.post('/algorithms/multi-skill/compare', params);
  }

  // Queue Management
  async getQueueMetrics(queueIds: string[]): Promise<any> {
    return apiClient.post('/queues/metrics', { queueIds });
  }

  async updateQueuePriorities(updates: Array<{ queueId: string; priority: string }>): Promise<any> {
    return apiClient.put('/queues/priorities', { updates });
  }

  async createQueueGroup(params: {
    name: string;
    queueIds: string[];
    aggregateMetrics: boolean;
  }): Promise<any> {
    return apiClient.post('/queues/groups', params);
  }
}

const wfmService = new WFMService();
export default wfmService;
export { WFMService };