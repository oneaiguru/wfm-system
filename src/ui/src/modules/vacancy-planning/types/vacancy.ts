// BDD: Vacancy Planning Module Types (Feature 27)

export interface VacancyPlanningSettings {
  minimumVacancyEfficiency: number; // 1-100%
  analysisPeriod: number; // 1-365 days
  forecastConfidence: number; // 50-99%
  workRuleOptimization: boolean;
  integrationWithExchange: boolean;
}

export interface WorkRuleParameter {
  shiftFlexibility: 'Fixed' | 'Flexible' | 'Hybrid';
  overtimeAllowance: number; // 0-20 hours/week
  crossTrainingUtilization: number; // 0-100%
  scheduleRotationFrequency: 'Daily' | 'Weekly' | 'Monthly';
}

export interface VacancyAnalysisRequest {
  period: {
    start: Date;
    end: Date;
  };
  positions: string[];
  constraints: {
    budget?: number;
    hiringLeadTime: number;
    minServiceLevel: number;
  };
}

export interface StaffingGap {
  position: string;
  department: string;
  deficit: number;
  skillsRequired: string[];
  priority: 'Critical' | 'High' | 'Medium' | 'Low';
  recommendedStartDate: Date;
}

export interface VacancyAnalysisResult {
  id: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  progress: number;
  currentStep: string;
  staffingGaps: StaffingGap[];
  totalDeficit: number;
  estimatedCost: number;
  serviceImpact: number;
  recommendations: HiringRecommendation[];
}

export interface HiringRecommendation {
  category: 'Immediate' | 'Planned' | 'Contingency' | 'SkillDevelopment';
  position: string;
  quantity: number;
  priorityLevel: 'Critical' | 'High' | 'Medium' | 'Low';
  timeline: string;
  skillRequirements: string[];
  workSchedule: string;
  salaryRange: {
    min: number;
    max: number;
  };
  startDate: Date;
  businessJustification: string;
}

export interface VacancyTask {
  id: string;
  name: string;
  status: 'queued' | 'running' | 'completed' | 'failed';
  priority: 'High' | 'Medium' | 'Low';
  progress: number;
  startTime: Date;
  estimatedCompletion: Date;
  error?: string;
}

export interface ExchangeSystemTransfer {
  dataType: 'StaffingGaps' | 'SkillRequirements' | 'ScheduleNeeds' | 'PriorityLevels';
  transferStatus: 'pending' | 'transferring' | 'completed' | 'failed';
  recordsTransferred: number;
  lastSyncTime: Date;
}

export interface VacancyReport {
  type: 'ExecutiveSummary' | 'DetailedAnalysis' | 'HiringJustification' | 'ImplementationPlan';
  format: 'PDF' | 'Excel' | 'Word' | 'PowerPoint';
  sections: {
    currentState: boolean;
    gapAnalysis: boolean;
    recommendations: boolean;
    financialImpact: boolean;
    implementationTimeline: boolean;
  };
}

export interface ScenarioAnalysis {
  name: string;
  type: 'BudgetConstraints' | 'ServiceLevelChanges' | 'ForecastVariations' | 'SkillDevelopment';
  parameters: Record<string, any>;
  results: VacancyAnalysisResult;
}