export interface Employee {
  id: string;
  name: string;
  department: string;
  skills: string[];
  proficiencyLevels: Record<string, number>;
  availability: 'available' | 'busy' | 'offline';
  maxCapacity: number;
  currentLoad: number;
  efficiency: number;
  costPerHour: number;
}

export interface Skill {
  id: string;
  name: string;
  queueId: string;
  category: string;
  requiredCoverage: number;
  currentCoverage: number;
  priority: 'high' | 'medium' | 'low';
  avgHandleTime: number;
  complexity: number;
}

export interface Queue {
  id: string;
  name: string;
  type: 'voice' | 'email' | 'chat' | 'video';
  volume: number;
  serviceLevel: number;
  targetServiceLevel: number;
  requiredSkills: string[];
  priority: 'high' | 'medium' | 'low';
  department: string;
  currentVolume: number;
  avgHandleTime: number;
  requiredOperators: number;
  assignedOperators: number;
  skills: string[];
  lastUpdated: Date;
}

export interface SkillAssignment {
  employeeId: string;
  skillId: string;
  proficiency: 1 | 2 | 3 | 4 | 5;
  isPrimary: boolean;
  lastUsed: Date;
  performanceScore: number;
}

export interface QueueGroup {
  id: string;
  name: string;
  queues: string[];
  aggregateMetrics: boolean;
}

export interface QueueMetrics {
  queueId: string;
  intervalData: {
    time: string;
    volume: number;
    aht: number;
    serviceLevel: number;
    operators: number;
  }[];
  dailyPattern: number[];
  weeklyPattern: number[];
}

export interface OptimizationScenario {
  id: string;
  name: string;
  description: string;
  targetAccuracy: number;
  predictedAccuracy: number;
  operatorCount: number;
  skillDistribution: Record<string, number>;
  costImpact: number;
  implementationTime: string;
  recommendations: string[];
}

export interface SkillGap {
  skillId: string;
  skillName: string;
  currentCoverage: number;
  requiredCoverage: number;
  gap: number;
  priority: 'critical' | 'high' | 'medium' | 'low';
  impactOnAccuracy: number;
}

export interface OptimizationMetrics {
  currentAccuracy: number;
  argusAccuracy: number;
  potentialAccuracy: number;
  efficiencyGain: number;
  costSavings: number;
  implementationComplexity: 'low' | 'medium' | 'high';
}

export interface OptimizationResult {
  assignments: SkillAssignment[];
  metrics: {
    accuracy: number;
    coverage: number;
    efficiency: number;
    cost: number;
    gaps: SkillGap[];
  };
  recommendations: string[];
  comparisonWithArgus: {
    accuracyDiff: number;
    efficiencyDiff: number;
    costSavings: number;
  };
}

export interface OptimizationParams {
  mode: 'accuracy' | 'efficiency' | 'balanced';
  constraints: {
    minServiceLevel?: number;
    maxCost?: number;
    minCoverage?: number;
    allowOvertime?: boolean;
  };
  weights: {
    accuracy: number;
    efficiency: number;
    cost: number;
    coverage: number;
  };
}