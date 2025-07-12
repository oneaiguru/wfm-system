/**
 * Growth Factor Calculation Utilities
 * Provides mathematical functions for scaling forecasts and calculating impacts
 */

import { format, eachDayOfInterval, eachHourOfInterval, startOfDay, endOfDay } from 'date-fns';

export interface GrowthCalculationParams {
  baseValue: number;
  growthType: 'percentage' | 'absolute';
  growthValue: number;
  compoundPeriods?: number;
}

export interface DistributionParams {
  totalGrowth: number;
  distribution: { [key: string]: number };
  maintainProportions: boolean;
}

export interface ErlangCParams {
  callVolume: number;
  avgHandleTime: number;
  avgWaitTime: number;
  serviceLevel: number;
  shrinkage: number;
}

/**
 * Calculate simple growth based on type
 */
export const calculateGrowth = (params: GrowthCalculationParams): number => {
  const { baseValue, growthType, growthValue, compoundPeriods = 1 } = params;
  
  if (growthType === 'percentage') {
    const growthRate = growthValue / 100;
    if (compoundPeriods > 1) {
      // Compound growth formula: P(1 + r)^n
      return baseValue * Math.pow(1 + growthRate, compoundPeriods);
    }
    return baseValue * (1 + growthRate);
  } else {
    // Absolute growth
    return baseValue + (growthValue * compoundPeriods);
  }
};

/**
 * Distribute growth across multiple skills/queues
 */
export const distributeGrowth = (params: DistributionParams): { [key: string]: number } => {
  const { totalGrowth, distribution, maintainProportions } = params;
  const result: { [key: string]: number } = {};
  
  if (maintainProportions) {
    // Distribute proportionally based on current percentages
    Object.entries(distribution).forEach(([key, percentage]) => {
      result[key] = (totalGrowth * percentage) / 100;
    });
  } else {
    // Equal distribution
    const keys = Object.keys(distribution);
    const equalShare = totalGrowth / keys.length;
    keys.forEach(key => {
      result[key] = equalShare;
    });
  }
  
  return result;
};

/**
 * Calculate operator requirements using simplified Erlang C
 * This is a demonstration version - real Erlang C is more complex
 */
export const calculateOperatorRequirement = (params: ErlangCParams): number => {
  const { callVolume, avgHandleTime, avgWaitTime, serviceLevel, shrinkage } = params;
  
  // Calculate offered load (Erlangs)
  const offeredLoad = (callVolume * avgHandleTime) / 3600; // Convert to hours
  
  // Start with minimum agents (offered load rounded up)
  let agents = Math.ceil(offeredLoad);
  
  // Iteratively increase agents until service level is met
  // This is a simplified version - real Erlang C uses more complex probability calculations
  let currentServiceLevel = 0;
  const maxIterations = 100;
  let iterations = 0;
  
  while (currentServiceLevel < serviceLevel && iterations < maxIterations) {
    // Calculate utilization
    const utilization = offeredLoad / agents;
    
    if (utilization >= 1) {
      agents++;
      iterations++;
      continue;
    }
    
    // Simplified service level calculation
    // Real Erlang C would use Poisson distribution here
    const waitProbability = Math.pow(utilization, agents) / 
      (1 - utilization + Math.pow(utilization, agents));
    
    // Estimate service level based on wait time
    const avgWaitTimeCalc = waitProbability * avgHandleTime / (agents * (1 - utilization));
    currentServiceLevel = avgWaitTimeCalc <= avgWaitTime ? 90 : 70; // Simplified
    
    if (currentServiceLevel < serviceLevel) {
      agents++;
    }
    iterations++;
  }
  
  // Apply shrinkage factor
  const requiredAgents = agents / (1 - shrinkage / 100);
  
  return Math.ceil(requiredAgents);
};

/**
 * Generate time-series growth projection
 */
export const generateGrowthProjection = (
  startDate: Date,
  endDate: Date,
  baseValue: number,
  growthConfig: any,
  interval: 'hourly' | 'daily' = 'daily'
): Array<{ timestamp: Date; value: number; growth: number }> => {
  const intervals = interval === 'hourly' 
    ? eachHourOfInterval({ start: startDate, end: endDate })
    : eachDayOfInterval({ start: startDate, end: endDate });
  
  const totalIntervals = intervals.length;
  
  return intervals.map((timestamp, index) => {
    const progress = index / (totalIntervals - 1);
    let growthMultiplier = 1;
    
    // Apply growth pattern
    switch (growthConfig.growthPattern) {
      case 'exponential':
        growthMultiplier = 1 + (growthConfig.growthMultiplier - 1) * Math.pow(progress, 2);
        break;
      case 'seasonal':
        const seasonalFactor = 1 + 0.2 * Math.sin(index * Math.PI / 30); // 30-day cycle
        growthMultiplier = growthConfig.growthMultiplier * seasonalFactor;
        break;
      case 'linear':
      default:
        growthMultiplier = 1 + (growthConfig.growthMultiplier - 1) * progress;
    }
    
    const value = baseValue * growthMultiplier;
    const growth = (growthMultiplier - 1) * 100;
    
    return { timestamp, value, growth };
  });
};

/**
 * Calculate compound annual growth rate (CAGR)
 */
export const calculateCAGR = (
  initialValue: number,
  finalValue: number,
  periods: number
): number => {
  if (initialValue <= 0 || finalValue <= 0 || periods <= 0) {
    return 0;
  }
  
  const cagr = Math.pow(finalValue / initialValue, 1 / periods) - 1;
  return cagr * 100; // Return as percentage
};

/**
 * Validate growth scenario for realism
 */
export const validateGrowthScenario = (
  currentVolume: number,
  targetVolume: number,
  timeframeDays: number
): { valid: boolean; warnings: string[]; recommendations: string[] } => {
  const warnings: string[] = [];
  const recommendations: string[] = [];
  
  const growthMultiplier = targetVolume / currentVolume;
  const dailyGrowthRate = Math.pow(growthMultiplier, 1 / timeframeDays) - 1;
  
  // Check for unrealistic growth
  if (growthMultiplier > 10) {
    warnings.push(`Growth of ${growthMultiplier.toFixed(1)}x may be unrealistic`);
    recommendations.push('Consider a phased approach or longer timeframe');
  }
  
  if (dailyGrowthRate > 0.1) { // 10% daily growth
    warnings.push(`Daily growth rate of ${(dailyGrowthRate * 100).toFixed(1)}% is very aggressive`);
    recommendations.push('Review capacity constraints and hiring plans');
  }
  
  if (growthMultiplier > 5 && timeframeDays < 90) {
    warnings.push('Rapid scaling may impact service quality');
    recommendations.push('Plan for additional training and quality monitoring');
  }
  
  // Check for operational impacts
  const additionalOperators = Math.ceil((targetVolume - currentVolume) / 50); // Rough estimate
  if (additionalOperators > 100) {
    warnings.push(`Estimated need for ${additionalOperators}+ additional operators`);
    recommendations.push('Consider automation and self-service options');
  }
  
  return {
    valid: warnings.length === 0,
    warnings,
    recommendations
  };
};

/**
 * Calculate ROI of growth investment
 */
export const calculateGrowthROI = (
  additionalVolume: number,
  revenuePerCall: number,
  additionalOperators: number,
  operatorCostPerMonth: number,
  timeframeMonths: number
): { roi: number; breakEvenMonths: number; totalRevenue: number; totalCost: number } => {
  const monthlyRevenue = additionalVolume * revenuePerCall * 30; // Assuming 30 days/month
  const monthlyCost = additionalOperators * operatorCostPerMonth;
  
  const totalRevenue = monthlyRevenue * timeframeMonths;
  const totalCost = monthlyCost * timeframeMonths;
  
  const roi = ((totalRevenue - totalCost) / totalCost) * 100;
  const breakEvenMonths = totalCost / monthlyRevenue;
  
  return {
    roi,
    breakEvenMonths: Math.ceil(breakEvenMonths),
    totalRevenue,
    totalCost
  };
};

/**
 * Format growth statistics for display
 */
export const formatGrowthStats = (
  originalValue: number,
  newValue: number,
  config: any
): { [key: string]: string } => {
  const absoluteChange = newValue - originalValue;
  const percentageChange = ((newValue - originalValue) / originalValue) * 100;
  const multiplier = newValue / originalValue;
  
  return {
    'Original Value': originalValue.toLocaleString(),
    'New Value': newValue.toLocaleString(),
    'Absolute Change': `${absoluteChange > 0 ? '+' : ''}${absoluteChange.toLocaleString()}`,
    'Percentage Change': `${percentageChange > 0 ? '+' : ''}${percentageChange.toFixed(1)}%`,
    'Growth Multiplier': `${multiplier.toFixed(2)}x`,
    'Growth Type': config.growthType,
    'Growth Pattern': config.growthPattern,
    'Time Period': `${format(config.period.start, 'MMM d')} - ${format(config.period.end, 'MMM d, yyyy')}`
  };
};