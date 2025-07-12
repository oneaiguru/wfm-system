/**
 * WFM Enterprise API Integration Service
 * Comprehensive service for connecting UI components to 110+ API endpoints
 * Handles data transformation, error handling, and real-time updates
 */

import apiClient from './apiClient';
import { wfmWebSocket, WebSocketEventType } from '../../../websocket-client';

// ===== TYPE DEFINITIONS =====

export interface DashboardData {
  realTimeMetrics: {
    agentsOnline: number;
    callsInQueue: number;
    serviceLevel: number;
    avgWaitTime: number;
    abandonmentRate: number;
    scheduleAdherence: number;
    forecastAccuracy: number;
    systemHealth: 'healthy' | 'warning' | 'critical';
  };
  alerts: Alert[];
  recentActivity: Activity[];
  trends: TrendData[];
}

export interface Alert {
  id: string;
  type: 'sla' | 'system' | 'schedule' | 'forecast';
  severity: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  message: string;
  timestamp: string;
  acknowledged: boolean;
  source: string;
}

export interface Activity {
  id: string;
  type: 'schedule_change' | 'agent_status' | 'forecast_update' | 'request_action';
  description: string;
  timestamp: string;
  user?: string;
  metadata?: Record<string, any>;
}

export interface TrendData {
  metric: string;
  data: Array<{ timestamp: string; value: number }>;
  change: number;
  unit: string;
}

export interface ScheduleData {
  scheduleId: string;
  agents: AgentSchedule[];
  shifts: ShiftDefinition[];
  coverage: CoverageAnalysis;
  conflicts: ScheduleConflict[];
  optimization: OptimizationSuggestions;
}

export interface AgentSchedule {
  agentId: string;
  name: string;
  skills: string[];
  shifts: AgentShift[];
  totalHours: number;
  scheduleAdherence: number;
  currentStatus: 'available' | 'busy' | 'break' | 'offline';
}

export interface AgentShift {
  shiftId: string;
  startTime: string;
  endTime: string;
  duration: number;
  type: 'regular' | 'overtime' | 'break';
  skills: string[];
  location?: string;
}

export interface ShiftDefinition {
  id: string;
  name: string;
  startTime: string;
  endTime: string;
  duration: number;
  requiredSkills: string[];
  capacity: number;
  assigned: number;
  available: number;
}

export interface CoverageAnalysis {
  intervals: CoverageInterval[];
  gaps: StaffingGap[];
  overStaffing: OverStaffingPeriod[];
  totalCoverage: number;
  skillCoverage: Record<string, number>;
}

export interface CoverageInterval {
  timestamp: string;
  required: number;
  available: number;
  coverage: number;
  skillBreakdown: Record<string, { required: number; available: number }>;
}

export interface StaffingGap {
  startTime: string;
  endTime: string;
  shortfall: number;
  affectedSkills: string[];
  severity: 'low' | 'medium' | 'high' | 'critical';
  suggestedActions: string[];
}

export interface OverStaffingPeriod {
  startTime: string;
  endTime: string;
  excess: number;
  cost: number;
  redeploymentOptions: string[];
}

export interface ScheduleConflict {
  id: string;
  type: 'double_booking' | 'skill_shortage' | 'overtime_limit' | 'availability';
  agentId?: string;
  description: string;
  severity: 'low' | 'medium' | 'high';
  autoResolvable: boolean;
  resolutionOptions: string[];
}

export interface OptimizationSuggestions {
  totalSavings: number;
  suggestions: OptimizationSuggestion[];
  implementationComplexity: 'low' | 'medium' | 'high';
  expectedImpact: number;
}

export interface OptimizationSuggestion {
  id: string;
  type: 'shift_swap' | 'skill_reallocation' | 'break_adjustment' | 'overtime_reduction';
  description: string;
  impact: number;
  cost: number;
  feasibility: number;
  agentsAffected: string[];
}

export interface ForecastData {
  forecastId: string;
  timeRange: { start: string; end: string };
  intervals: ForecastInterval[];
  accuracy: AccuracyMetrics;
  scenarios: ForecastScenario[];
  adjustments: ForecastAdjustment[];
}

export interface ForecastInterval {
  timestamp: string;
  predictedVolume: number;
  confidenceInterval: { lower: number; upper: number };
  requiredAgents: number;
  aht: number;
  serviceLevel: number;
  skills: Record<string, number>;
}

export interface AccuracyMetrics {
  mape: number;
  rmse: number;
  mae: number;
  r2: number;
  lastUpdated: string;
  historicalAccuracy: Array<{ period: string; accuracy: number }>;
}

export interface ForecastScenario {
  id: string;
  name: string;
  description: string;
  parameters: Record<string, any>;
  results: ForecastInterval[];
  probability: number;
}

export interface ForecastAdjustment {
  id: string;
  timestamp: string;
  reason: string;
  adjustment: number;
  user: string;
  approved: boolean;
}

export interface PersonnelData {
  employees: Employee[];
  departments: Department[];
  skills: Skill[];
  groups: Group[];
  organizationChart: OrganizationNode[];
}

export interface Employee {
  id: string;
  name: string;
  email: string;
  department: string;
  position: string;
  skills: EmployeeSkill[];
  schedule: string;
  status: 'active' | 'inactive' | 'on_leave';
  hireDate: string;
  contactInfo: ContactInfo;
  performance: PerformanceMetrics;
}

export interface EmployeeSkill {
  skillId: string;
  level: number;
  certified: boolean;
  certificationDate?: string;
  expiryDate?: string;
}

export interface Department {
  id: string;
  name: string;
  managerId: string;
  parentId?: string;
  employeeCount: number;
  budget: number;
  location: string;
}

export interface Skill {
  id: string;
  name: string;
  description: string;
  category: string;
  required: boolean;
  certificationRequired: boolean;
  trainingDuration: number;
}

export interface Group {
  id: string;
  name: string;
  description: string;
  memberIds: string[];
  managerId: string;
  type: 'functional' | 'project' | 'temporary';
}

export interface OrganizationNode {
  id: string;
  name: string;
  type: 'department' | 'team' | 'employee';
  parentId?: string;
  children: OrganizationNode[];
  metadata: Record<string, any>;
}

export interface ContactInfo {
  phone: string;
  mobile: string;
  address: string;
  emergencyContact: string;
}

export interface PerformanceMetrics {
  overallRating: number;
  kpis: Record<string, number>;
  goals: Goal[];
  reviews: Review[];
}

export interface Goal {
  id: string;
  title: string;
  description: string;
  targetValue: number;
  currentValue: number;
  deadline: string;
  status: 'not_started' | 'in_progress' | 'completed' | 'overdue';
}

export interface Review {
  id: string;
  date: string;
  rating: number;
  comments: string;
  reviewerId: string;
  period: string;
}

// ===== API INTEGRATION SERVICE =====

class ApiIntegrationService {
  private websocketConnected = false;
  private subscriptions = new Map<string, Array<(data: any) => void>>();
  private cache = new Map<string, { data: any; timestamp: number; ttl: number }>();

  constructor() {
    this.initializeWebSocket();
  }

  // ===== WEBSOCKET INTEGRATION =====

  private initializeWebSocket() {
    wfmWebSocket.connect().then(() => {
      this.websocketConnected = true;
      this.setupEventHandlers();
    }).catch(error => {
      console.error('WebSocket connection failed:', error);
    });
  }

  private setupEventHandlers() {
    // Dashboard updates
    wfmWebSocket.onAgentStatusChanged((payload) => {
      this.notifySubscribers('agent_status', payload);
    });

    wfmWebSocket.onQueueMetricsUpdate((payload) => {
      this.notifySubscribers('queue_metrics', payload);
    });

    wfmWebSocket.onSLAAlert((payload) => {
      this.notifySubscribers('sla_alert', payload);
    });

    // Schedule updates
    wfmWebSocket.onScheduleChanged((payload) => {
      this.notifySubscribers('schedule_changed', payload);
      this.invalidateCache('schedule_*');
    });

    wfmWebSocket.onScheduleOptimized((payload) => {
      this.notifySubscribers('schedule_optimized', payload);
    });

    // Forecast updates
    wfmWebSocket.onForecastCalculated((payload) => {
      this.notifySubscribers('forecast_updated', payload);
      this.invalidateCache('forecast_*');
    });

    // Skill updates
    wfmWebSocket.onSkillAssigned((payload) => {
      this.notifySubscribers('skill_assigned', payload);
      this.invalidateCache('personnel_*');
    });

    // Vacancy updates
    wfmWebSocket.onVacancyCreated((payload) => {
      this.notifySubscribers('vacancy_created', payload);
    });

    wfmWebSocket.onStaffingGapDetected((payload) => {
      this.notifySubscribers('staffing_gap', payload);
    });

    // Algorithm updates
    wfmWebSocket.onErlangCalculationComplete((payload) => {
      this.notifySubscribers('calculation_complete', payload);
    });

    wfmWebSocket.onOptimizationComplete((payload) => {
      this.notifySubscribers('optimization_complete', payload);
    });
  }

  // ===== SUBSCRIPTION MANAGEMENT =====

  subscribe(eventType: string, callback: (data: any) => void) {
    if (!this.subscriptions.has(eventType)) {
      this.subscriptions.set(eventType, []);
    }
    this.subscriptions.get(eventType)!.push(callback);

    // Join appropriate WebSocket room
    if (this.websocketConnected) {
      wfmWebSocket.joinRoom(eventType);
    }

    return () => {
      const callbacks = this.subscriptions.get(eventType);
      if (callbacks) {
        const index = callbacks.indexOf(callback);
        if (index > -1) {
          callbacks.splice(index, 1);
        }
      }
    };
  }

  private notifySubscribers(eventType: string, data: any) {
    const callbacks = this.subscriptions.get(eventType);
    if (callbacks) {
      callbacks.forEach(callback => callback(data));
    }
  }

  // ===== CACHE MANAGEMENT =====

  private setCache(key: string, data: any, ttl: number = 300000) { // 5 minutes default
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl
    });
  }

  private getCache(key: string): any | null {
    const cached = this.cache.get(key);
    if (!cached) return null;

    if (Date.now() - cached.timestamp > cached.ttl) {
      this.cache.delete(key);
      return null;
    }

    return cached.data;
  }

  private invalidateCache(pattern: string) {
    const keys = Array.from(this.cache.keys());
    keys.forEach(key => {
      if (pattern.includes('*')) {
        const regex = new RegExp(pattern.replace('*', '.*'));
        if (regex.test(key)) {
          this.cache.delete(key);
        }
      } else if (key === pattern) {
        this.cache.delete(key);
      }
    });
  }

  // ===== DASHBOARD INTEGRATION =====

  async getDashboardData(): Promise<DashboardData> {
    const cacheKey = 'dashboard_data';
    const cached = this.getCache(cacheKey);
    if (cached) return cached;

    try {
      const [realTimeMetrics, alerts, recentActivity, trends] = await Promise.all([
        this.getRealTimeMetrics(),
        this.getAlerts(),
        this.getRecentActivity(),
        this.getTrends()
      ]);

      const dashboardData: DashboardData = {
        realTimeMetrics,
        alerts,
        recentActivity,
        trends
      };

      this.setCache(cacheKey, dashboardData, 60000); // 1 minute cache
      return dashboardData;
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
      throw error;
    }
  }

  private async getRealTimeMetrics() {
    const response = await apiClient.get('/argus/ccwfm/status');
    return {
      agentsOnline: response.agents_online || 0,
      callsInQueue: response.calls_in_queue || 0,
      serviceLevel: response.service_level || 0,
      avgWaitTime: response.avg_wait_time || 0,
      abandonmentRate: response.abandonment_rate || 0,
      scheduleAdherence: response.schedule_adherence || 0,
      forecastAccuracy: response.forecast_accuracy || 0,
      systemHealth: response.system_health || 'healthy'
    };
  }

  private async getAlerts(): Promise<Alert[]> {
    const response = await apiClient.get('/monitoring/alerts');
    return response.alerts || [];
  }

  private async getRecentActivity(): Promise<Activity[]> {
    const response = await apiClient.get('/activity/recent');
    return response.activities || [];
  }

  private async getTrends(): Promise<TrendData[]> {
    const response = await apiClient.get('/analytics/trends');
    return response.trends || [];
  }

  // ===== SCHEDULE MANAGEMENT =====

  async getScheduleData(scheduleId?: string): Promise<ScheduleData> {
    const cacheKey = `schedule_${scheduleId || 'current'}`;
    const cached = this.getCache(cacheKey);
    if (cached) return cached;

    try {
      const endpoint = scheduleId ? `/schedules/${scheduleId}` : '/schedules/current';
      const response = await apiClient.get(endpoint);

      const scheduleData: ScheduleData = {
        scheduleId: response.id,
        agents: response.agents || [],
        shifts: response.shifts || [],
        coverage: response.coverage || { intervals: [], gaps: [], overStaffing: [], totalCoverage: 0, skillCoverage: {} },
        conflicts: response.conflicts || [],
        optimization: response.optimization || { totalSavings: 0, suggestions: [], implementationComplexity: 'low', expectedImpact: 0 }
      };

      this.setCache(cacheKey, scheduleData, 300000); // 5 minutes
      return scheduleData;
    } catch (error) {
      console.error('Failed to load schedule data:', error);
      throw error;
    }
  }

  async updateSchedule(scheduleId: string, updates: Partial<ScheduleData>): Promise<void> {
    await apiClient.put(`/schedules/${scheduleId}`, updates);
    this.invalidateCache(`schedule_${scheduleId}`);
  }

  async optimizeSchedule(scheduleId: string, parameters: Record<string, any>): Promise<OptimizationSuggestions> {
    const response = await apiClient.post(`/schedules/${scheduleId}/optimize`, parameters);
    this.invalidateCache(`schedule_${scheduleId}`);
    return response.optimization;
  }

  async publishSchedule(scheduleId: string): Promise<void> {
    await apiClient.post(`/schedules/${scheduleId}/publish`);
    this.invalidateCache(`schedule_${scheduleId}`);
  }

  // ===== FORECAST MANAGEMENT =====

  async getForecastData(forecastId?: string): Promise<ForecastData> {
    const cacheKey = `forecast_${forecastId || 'current'}`;
    const cached = this.getCache(cacheKey);
    if (cached) return cached;

    try {
      const endpoint = forecastId ? `/forecasts/${forecastId}` : '/forecasts/current';
      const response = await apiClient.get(endpoint);

      const forecastData: ForecastData = {
        forecastId: response.id,
        timeRange: response.time_range,
        intervals: response.intervals || [],
        accuracy: response.accuracy || { mape: 0, rmse: 0, mae: 0, r2: 0, lastUpdated: '', historicalAccuracy: [] },
        scenarios: response.scenarios || [],
        adjustments: response.adjustments || []
      };

      this.setCache(cacheKey, forecastData, 600000); // 10 minutes
      return forecastData;
    } catch (error) {
      console.error('Failed to load forecast data:', error);
      throw error;
    }
  }

  async generateForecast(parameters: Record<string, any>): Promise<ForecastData> {
    const response = await apiClient.post('/forecasts/generate', parameters);
    this.invalidateCache('forecast_*');
    return response;
  }

  async adjustForecast(forecastId: string, adjustments: ForecastAdjustment[]): Promise<void> {
    await apiClient.post(`/forecasts/${forecastId}/adjust`, { adjustments });
    this.invalidateCache(`forecast_${forecastId}`);
  }

  // ===== PERSONNEL MANAGEMENT =====

  async getPersonnelData(): Promise<PersonnelData> {
    const cacheKey = 'personnel_data';
    const cached = this.getCache(cacheKey);
    if (cached) return cached;

    try {
      const [employees, departments, skills, groups, organization] = await Promise.all([
        apiClient.get('/personnel/employees'),
        apiClient.get('/personnel/departments'),
        apiClient.get('/personnel/skills'),
        apiClient.get('/personnel/groups'),
        apiClient.get('/organization/structure')
      ]);

      const personnelData: PersonnelData = {
        employees: employees.data || [],
        departments: departments.data || [],
        skills: skills.data || [],
        groups: groups.data || [],
        organizationChart: organization.data || []
      };

      this.setCache(cacheKey, personnelData, 1800000); // 30 minutes
      return personnelData;
    } catch (error) {
      console.error('Failed to load personnel data:', error);
      throw error;
    }
  }

  async updateEmployee(employeeId: string, updates: Partial<Employee>): Promise<void> {
    await apiClient.put(`/personnel/employees/${employeeId}`, updates);
    this.invalidateCache('personnel_*');
  }

  async assignSkill(employeeId: string, skillId: string, level: number): Promise<void> {
    await apiClient.post(`/personnel/employees/${employeeId}/skills`, { skillId, level });
    this.invalidateCache('personnel_*');
  }

  async createGroup(group: Omit<Group, 'id'>): Promise<Group> {
    const response = await apiClient.post('/personnel/groups', group);
    this.invalidateCache('personnel_*');
    return response.data;
  }

  // ===== ALGORITHM INTEGRATION =====

  async calculateErlangC(parameters: Record<string, any>): Promise<any> {
    return await apiClient.post('/algorithms/erlang-c/calculate', parameters);
  }

  async runMultiSkillOptimization(parameters: Record<string, any>): Promise<any> {
    return await apiClient.post('/algorithms/multi-skill/optimize', parameters);
  }

  async getAlgorithmStatus(): Promise<any> {
    return await apiClient.get('/algorithms/status');
  }

  // ===== REPORTING =====

  async generateReport(reportType: string, parameters: Record<string, any>): Promise<any> {
    return await apiClient.post(`/reports/${reportType}/generate`, parameters);
  }

  async getReportStatus(reportId: string): Promise<any> {
    return await apiClient.get(`/reports/${reportId}/status`);
  }

  async downloadReport(reportId: string): Promise<Blob> {
    return await apiClient.get(`/reports/${reportId}/download`, { responseType: 'blob' });
  }

  // ===== INTEGRATION MANAGEMENT =====

  async getIntegrationStatus(): Promise<any> {
    return await apiClient.get('/integrations/status');
  }

  async testIntegration(integrationType: string): Promise<any> {
    return await apiClient.post(`/integrations/${integrationType}/test`);
  }

  async syncExternalData(integrationType: string, parameters: Record<string, any>): Promise<any> {
    return await apiClient.post(`/integrations/${integrationType}/sync`, parameters);
  }

  // ===== UTILITY METHODS =====

  isWebSocketConnected(): boolean {
    return this.websocketConnected;
  }

  async healthCheck(): Promise<any> {
    return await apiClient.get('/health');
  }

  getCacheStats(): any {
    return {
      size: this.cache.size,
      keys: Array.from(this.cache.keys()),
      subscriptions: this.subscriptions.size
    };
  }

  clearCache(): void {
    this.cache.clear();
  }
}

// ===== SINGLETON INSTANCE =====

const apiIntegrationService = new ApiIntegrationService();
export default apiIntegrationService;
export { ApiIntegrationService };