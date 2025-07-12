import { useState, useCallback, useMemo } from 'react';
import { addDays, differenceInDays, isWithinInterval, startOfDay, endOfDay } from 'date-fns';

interface GrowthFactorConfig {
  period: {
    start: Date;
    end: Date;
  };
  growthType: 'percentage' | 'absolute';
  growthValue: number;
  applyTo: 'volume' | 'both' | 'aht';
  volumeGrowth: number;
  ahtGrowth: number;
  maintainDistribution: boolean;
  skillDistribution?: { [skillId: string]: number };
  compoundGrowth: boolean;
  growthPattern: 'linear' | 'exponential' | 'seasonal';
}

interface ForecastDataPoint {
  timestamp: Date | string;
  callVolume: number;
  aht: number;
  skillId?: string;
  confidence?: number;
}

interface UseGrowthFactorReturn {
  applyGrowthFactor: (data: ForecastDataPoint[], config: GrowthFactorConfig) => ForecastDataPoint[];
  calculateGrowthImpact: (baseValue: number, config: GrowthFactorConfig) => number;
  validateGrowthConfig: (config: GrowthFactorConfig) => { valid: boolean; errors: string[] };
  getGrowthMultiplier: (config: GrowthFactorConfig) => number;
  generateGrowthPreview: (config: GrowthFactorConfig, sampleSize?: number) => any;
  calculateOperatorImpact: (currentOperators: number, config: GrowthFactorConfig) => number;
}

export const useGrowthFactor = (): UseGrowthFactorReturn => {
  /**
   * Apply growth factor to forecast data
   */
  const applyGrowthFactor = useCallback((
    data: ForecastDataPoint[],
    config: GrowthFactorConfig
  ): ForecastDataPoint[] => {
    return data.map((point, index) => {
      const pointDate = typeof point.timestamp === 'string' 
        ? new Date(point.timestamp) 
        : point.timestamp;

      // Check if point is within the growth period
      const isInPeriod = isWithinInterval(pointDate, {
        start: startOfDay(config.period.start),
        end: endOfDay(config.period.end)
      });

      if (!isInPeriod) {
        return point;
      }

      // Calculate progress through the period (0 to 1)
      const periodDuration = differenceInDays(config.period.end, config.period.start);
      const daysSinceStart = differenceInDays(pointDate, config.period.start);
      const progress = periodDuration > 0 ? daysSinceStart / periodDuration : 0;

      // Calculate volume multiplier
      let volumeMultiplier = 1;
      if (config.applyTo !== 'aht') {
        if (config.growthType === 'percentage') {
          volumeMultiplier = 1 + (config.volumeGrowth / 100);
        } else {
          volumeMultiplier = (point.callVolume + config.volumeGrowth) / point.callVolume;
        }

        // Apply growth pattern
        volumeMultiplier = applyGrowthPattern(volumeMultiplier, progress, index, config);
      }

      // Calculate AHT multiplier
      let ahtMultiplier = 1;
      if (config.applyTo !== 'volume') {
        if (config.growthType === 'percentage') {
          ahtMultiplier = 1 + (config.ahtGrowth / 100);
        } else {
          ahtMultiplier = (point.aht + config.ahtGrowth) / point.aht;
        }

        // Apply growth pattern to AHT if needed
        if (config.growthPattern !== 'linear') {
          ahtMultiplier = applyGrowthPattern(ahtMultiplier, progress, index, config);
        }
      }

      // Apply skill distribution if applicable
      let skillAdjustedVolume = point.callVolume * volumeMultiplier;
      if (point.skillId && config.skillDistribution && config.skillDistribution[point.skillId]) {
        const skillWeight = config.skillDistribution[point.skillId] / 100;
        skillAdjustedVolume = point.callVolume * volumeMultiplier * skillWeight;
      }

      return {
        ...point,
        callVolume: Math.round(skillAdjustedVolume),
        aht: Math.round(point.aht * ahtMultiplier),
        growthApplied: true,
        originalVolume: point.callVolume,
        originalAHT: point.aht
      };
    });
  }, []);

  /**
   * Apply growth pattern modifiers
   */
  const applyGrowthPattern = (
    baseMultiplier: number,
    progress: number,
    index: number,
    config: GrowthFactorConfig
  ): number => {
    switch (config.growthPattern) {
      case 'exponential':
        // Exponential growth accelerates over time
        if (config.compoundGrowth) {
          return Math.pow(baseMultiplier, progress + 1);
        } else {
          return 1 + (baseMultiplier - 1) * Math.pow(progress, 2);
        }

      case 'seasonal':
        // Seasonal pattern with peaks and valleys
        const seasonalFactor = 1 + 0.2 * Math.sin(index * Math.PI / 6);
        return baseMultiplier * seasonalFactor;

      case 'linear':
      default:
        // Linear growth remains constant
        return baseMultiplier;
    }
  };

  /**
   * Calculate the impact of growth on a single value
   */
  const calculateGrowthImpact = useCallback((
    baseValue: number,
    config: GrowthFactorConfig
  ): number => {
    if (config.growthType === 'percentage') {
      return baseValue * (1 + config.volumeGrowth / 100);
    } else {
      return baseValue + config.volumeGrowth;
    }
  }, []);

  /**
   * Validate growth factor configuration
   */
  const validateGrowthConfig = useCallback((
    config: GrowthFactorConfig
  ): { valid: boolean; errors: string[] } => {
    const errors: string[] = [];

    // Validate period
    if (config.period.start >= config.period.end) {
      errors.push('End date must be after start date');
    }

    // Validate growth values
    if (config.growthType === 'percentage') {
      if (config.volumeGrowth < -100) {
        errors.push('Volume growth cannot be less than -100%');
      }
      if (config.ahtGrowth < -100) {
        errors.push('AHT growth cannot be less than -100%');
      }
      if (config.volumeGrowth > 1000) {
        errors.push('Volume growth greater than 1000% may be unrealistic');
      }
    } else {
      if (config.volumeGrowth < 0 && Math.abs(config.volumeGrowth) > 1000) {
        errors.push('Absolute volume reduction seems too large');
      }
    }

    // Validate skill distribution
    if (config.skillDistribution) {
      const totalDistribution = Object.values(config.skillDistribution).reduce((sum, val) => sum + val, 0);
      if (Math.abs(totalDistribution - 100) > 0.1) {
        errors.push('Skill distribution must sum to 100%');
      }
    }

    // Business logic validations
    if (config.volumeGrowth > 500 && config.growthType === 'percentage') {
      errors.push('Warning: Growth factor exceeds 500% - verify this is intended');
    }

    if (config.applyTo === 'both' && config.ahtGrowth > 50) {
      errors.push('Warning: AHT increase exceeds 50% - this will significantly impact operator requirements');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }, []);

  /**
   * Get the growth multiplier for display
   */
  const getGrowthMultiplier = useCallback((config: GrowthFactorConfig): number => {
    if (config.growthType === 'percentage') {
      return 1 + (config.volumeGrowth / 100);
    }
    // For absolute, return a representative multiplier based on typical volume
    return config.volumeGrowth > 0 ? config.volumeGrowth / 1000 : 1;
  }, []);

  /**
   * Generate preview data for visualization
   */
  const generateGrowthPreview = useCallback((
    config: GrowthFactorConfig,
    sampleSize: number = 12
  ): any => {
    const baseVolume = 1000;
    const baseAHT = 300;
    
    // Generate sample data points
    const originalData = [];
    const scaledData = [];
    
    for (let i = 0; i < sampleSize; i++) {
      const progress = i / (sampleSize - 1);
      const timestamp = addDays(config.period.start, 
        Math.floor(differenceInDays(config.period.end, config.period.start) * progress)
      );
      
      // Add some variation to make it realistic
      const variation = 0.9 + Math.random() * 0.2;
      const currentVolume = baseVolume * variation;
      const currentAHT = baseAHT * (0.95 + Math.random() * 0.1);
      
      originalData.push({
        timestamp,
        volume: currentVolume,
        aht: currentAHT
      });
      
      // Apply growth factor
      const scaled = applyGrowthFactor([{
        timestamp,
        callVolume: currentVolume,
        aht: currentAHT
      }], config)[0];
      
      scaledData.push({
        timestamp,
        volume: scaled.callVolume,
        aht: scaled.aht
      });
    }
    
    return {
      original: originalData,
      scaled: scaledData,
      summary: {
        avgVolumeIncrease: scaledData.reduce((sum, d) => sum + d.volume, 0) / 
                          originalData.reduce((sum, d) => sum + d.volume, 0) - 1,
        avgAHTChange: scaledData.reduce((sum, d) => sum + d.aht, 0) / 
                     originalData.reduce((sum, d) => sum + d.aht, 0) - 1,
        peakVolume: Math.max(...scaledData.map(d => d.volume)),
        minVolume: Math.min(...scaledData.map(d => d.volume))
      }
    };
  }, [applyGrowthFactor]);

  /**
   * Calculate the impact on operator requirements
   */
  const calculateOperatorImpact = useCallback((
    currentOperators: number,
    config: GrowthFactorConfig
  ): number => {
    // Simple Erlang C approximation for demo purposes
    let volumeMultiplier = 1;
    let ahtMultiplier = 1;

    if (config.applyTo !== 'aht') {
      volumeMultiplier = config.growthType === 'percentage' 
        ? 1 + (config.volumeGrowth / 100)
        : 1.5; // Approximate for absolute
    }

    if (config.applyTo !== 'volume') {
      ahtMultiplier = config.growthType === 'percentage'
        ? 1 + (config.ahtGrowth / 100)
        : 1.1; // Approximate for absolute
    }

    // Operator requirement is roughly proportional to (volume * AHT)
    // This is a simplification - real Erlang C is more complex
    const workloadMultiplier = volumeMultiplier * ahtMultiplier;
    
    // Add some overhead for increased complexity
    const complexityFactor = workloadMultiplier > 2 ? 1.1 : 1;
    
    return Math.ceil(currentOperators * workloadMultiplier * complexityFactor);
  }, []);

  return {
    applyGrowthFactor,
    calculateGrowthImpact,
    validateGrowthConfig,
    getGrowthMultiplier,
    generateGrowthPreview,
    calculateOperatorImpact
  };
};