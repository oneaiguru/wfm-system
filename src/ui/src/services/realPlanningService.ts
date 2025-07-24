/**
 * REAL Planning Service - SPEC-19 Integration  
 * NO MOCK DATA - connects to real INTEGRATION-OPUS planning endpoints
 * Supports: capacity planning, demand forecasting, scenario modeling, ROI analysis
 */

export interface CapacityPlan {
  id: string;
  name: string;
  department_id: string;
  department_name: string;
  current_staff: number;
  demand_forecast: number;
  capacity_gap: number;
  recommendation: string;
  confidence_level: number;
  planning_period: string;
  created_at: string;
  status: 'draft' | 'active' | 'approved' | 'archived';
}

export interface DemandForecast {
  id: string;
  period: string;
  forecast_type: 'call_volume' | 'staffing' | 'workload';
  predicted_value: number;
  confidence_interval: { min: number; max: number };
  accuracy_score: number;
  model_used: string;
  factors: string[];
  created_at: string;
}

export interface ScenarioAnalysis {
  id: string;
  scenario_name: string;
  description: string;
  assumptions: { [key: string]: any };
  results: {
    staffing_impact: number;
    cost_impact: number;
    service_level_impact: number;
    roi_score: number;
  };
  comparison_baseline: string;
  confidence: number;
  status: 'modeling' | 'complete' | 'approved';
}

export interface ROIAnalysis {
  id: string;
  project_name: string;
  investment_amount: number;
  payback_period: number;
  roi_percentage: number;
  npv: number;
  irr: number;
  cost_breakdown: { [category: string]: number };
  benefit_breakdown: { [category: string]: number };
  risk_assessment: 'low' | 'medium' | 'high';
  approval_status: 'pending' | 'approved' | 'rejected';
}

export interface PlanningDashboardData {
  summary: {
    total_plans: number;
    active_scenarios: number;
    avg_capacity_utilization: number;
    forecast_accuracy: number;
    pending_approvals: number;
  };
  recent_plans: CapacityPlan[];
  recent_forecasts: DemandForecast[];
  critical_alerts: {
    understaffed_departments: string[];
    low_forecast_accuracy: string[];
    overdue_approvals: string[];
  };
}

export interface PlanningApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  total_count?: number;
}

const API_BASE_URL = 'http://localhost:8001/api/v1';

class RealPlanningService {
  
  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<PlanningApiResponse<T>> {
    try {
      console.log(`[PLANNING API] Making request to: ${API_BASE_URL}${endpoint}`);
      
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
          'Accept-Language': 'ru-RU,en-US',
          ...options.headers,
        },
        ...options,
      });

      console.log(`[PLANNING API] Response status: ${response.status}`);

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[PLANNING API] Error response: ${errorText}`);
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      console.log(`[PLANNING API] Success response:`, data);
      
      return {
        success: true,
        data: data as T,
        total_count: data.total_count
      };

    } catch (error) {
      console.error(`[PLANNING API] Request failed:`, error);
      
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Произошла ошибка при обращении к API планирования'
      };
    }
  }

  private getAuthToken(): string {
    const token = localStorage.getItem('authToken');
    if (!token) {
      throw new Error('Токен аутентификации не найден');
    }
    return token;
  }

  // SPEC-19: Get planning dashboard data
  async getPlanningDashboard(): Promise<PlanningApiResponse<PlanningDashboardData>> {
    console.log('[PLANNING API] Fetching planning dashboard...');
    
    return this.makeRequest<PlanningDashboardData>('/planning/dashboard');
  }

  // SPEC-19: Get capacity plans
  async getCapacityPlans(filters?: { department?: string; status?: string }): Promise<PlanningApiResponse<CapacityPlan[]>> {
    console.log('[PLANNING API] Fetching capacity plans:', filters);
    
    const params = new URLSearchParams();
    if (filters?.department) params.append('department', filters.department);
    if (filters?.status) params.append('status', filters.status);
    
    const queryString = params.toString() ? `?${params.toString()}` : '';
    return this.makeRequest<CapacityPlan[]>(`/planning/capacity${queryString}`);
  }

  // SPEC-19: Create capacity plan
  async createCapacityPlan(planData: Partial<CapacityPlan>): Promise<PlanningApiResponse<CapacityPlan>> {
    console.log('[PLANNING API] Creating capacity plan:', planData);
    
    return this.makeRequest<CapacityPlan>('/planning/capacity', {
      method: 'POST',
      body: JSON.stringify(planData)
    });
  }

  // SPEC-19: Get demand forecasts
  async getDemandForecasts(period?: string): Promise<PlanningApiResponse<DemandForecast[]>> {
    console.log('[PLANNING API] Fetching demand forecasts for period:', period);
    
    const queryString = period ? `?period=${period}` : '';
    return this.makeRequest<DemandForecast[]>(`/planning/forecasts${queryString}`);
  }

  // SPEC-19: Generate demand forecast
  async generateDemandForecast(forecastRequest: {
    forecast_type: string;
    period: string;
    factors: string[];
  }): Promise<PlanningApiResponse<DemandForecast>> {
    console.log('[PLANNING API] Generating demand forecast:', forecastRequest);
    
    return this.makeRequest<DemandForecast>('/planning/forecasts/generate', {
      method: 'POST',
      body: JSON.stringify(forecastRequest)
    });
  }

  // SPEC-19: Get scenario analyses
  async getScenarioAnalyses(): Promise<PlanningApiResponse<ScenarioAnalysis[]>> {
    console.log('[PLANNING API] Fetching scenario analyses...');
    
    return this.makeRequest<ScenarioAnalysis[]>('/planning/scenarios');
  }

  // SPEC-19: Create scenario analysis
  async createScenarioAnalysis(scenarioData: Partial<ScenarioAnalysis>): Promise<PlanningApiResponse<ScenarioAnalysis>> {
    console.log('[PLANNING API] Creating scenario analysis:', scenarioData);
    
    return this.makeRequest<ScenarioAnalysis>('/planning/scenarios', {
      method: 'POST',
      body: JSON.stringify(scenarioData)
    });
  }

  // SPEC-19: Run scenario comparison
  async compareScenarios(scenarioIds: string[]): Promise<PlanningApiResponse<{
    comparison: { [key: string]: any };
    recommendations: string[];
  }>> {
    console.log('[PLANNING API] Comparing scenarios:', scenarioIds);
    
    return this.makeRequest<{
      comparison: { [key: string]: any };
      recommendations: string[];
    }>('/planning/scenarios/compare', {
      method: 'POST',
      body: JSON.stringify({ scenario_ids: scenarioIds })
    });
  }

  // SPEC-19: Get ROI analyses
  async getROIAnalyses(): Promise<PlanningApiResponse<ROIAnalysis[]>> {
    console.log('[PLANNING API] Fetching ROI analyses...');
    
    return this.makeRequest<ROIAnalysis[]>('/planning/roi');
  }

  // SPEC-19: Create ROI analysis
  async createROIAnalysis(roiData: Partial<ROIAnalysis>): Promise<PlanningApiResponse<ROIAnalysis>> {
    console.log('[PLANNING API] Creating ROI analysis:', roiData);
    
    return this.makeRequest<ROIAnalysis>('/planning/roi', {
      method: 'POST',
      body: JSON.stringify(roiData)
    });
  }

  // SPEC-19: Calculate workforce optimization
  async calculateWorkforceOptimization(parameters: {
    departments: string[];
    constraints: { [key: string]: any };
    objectives: string[];
  }): Promise<PlanningApiResponse<{
    optimal_allocation: { [department: string]: number };
    cost_savings: number;
    service_level_improvement: number;
    implementation_plan: string[];
  }>> {
    console.log('[PLANNING API] Calculating workforce optimization:', parameters);
    
    return this.makeRequest<{
      optimal_allocation: { [department: string]: number };
      cost_savings: number;
      service_level_improvement: number;
      implementation_plan: string[];
    }>('/planning/optimization/workforce', {
      method: 'POST',
      body: JSON.stringify(parameters)
    });
  }

  // SPEC-19: Export planning data
  async exportPlanningData(exportRequest: {
    data_type: 'capacity' | 'forecasts' | 'scenarios' | 'roi';
    format: 'excel' | 'pdf' | 'csv';
    filters?: { [key: string]: any };
  }): Promise<PlanningApiResponse<{ download_url: string }>> {
    console.log('[PLANNING API] Exporting planning data:', exportRequest);
    
    return this.makeRequest<{ download_url: string }>('/planning/export', {
      method: 'POST',
      body: JSON.stringify(exportRequest)
    });
  }

  // SPEC-19: Get planning workflows
  async getPlanningWorkflows(): Promise<PlanningApiResponse<{
    active_workflows: any[];
    pending_approvals: any[];
    completed_this_month: number;
  }>> {
    console.log('[PLANNING API] Fetching planning workflows...');
    
    return this.makeRequest<{
      active_workflows: any[];
      pending_approvals: any[];
      completed_this_month: number;
    }>('/planning/workflows');
  }

  // Health check for planning API endpoints
  async checkPlanningApiHealth(): Promise<boolean> {
    try {
      console.log('[PLANNING API] Checking planning API health...');
      
      const response = await fetch(`${API_BASE_URL}/health/planning`);
      const isHealthy = response.ok;
      
      console.log(`[PLANNING API] Planning API health status: ${isHealthy ? 'OK' : 'ERROR'}`);
      return isHealthy;
      
    } catch (error) {
      console.error('[PLANNING API] Health check failed:', error);
      return false;
    }
  }
}

export const realPlanningService = new RealPlanningService();
export default realPlanningService;