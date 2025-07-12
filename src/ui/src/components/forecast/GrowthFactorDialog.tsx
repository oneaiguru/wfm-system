import React, { useState, useEffect, useMemo } from 'react';
import { Line } from 'react-chartjs-2';
import { format, addMonths, startOfMonth, endOfMonth } from 'date-fns';

interface GrowthFactorDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onApply: (config: GrowthFactorConfig) => void;
  currentForecastData?: any;
  skills?: Skill[];
}

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

interface Skill {
  id: string;
  name: string;
  currentVolume: number;
  currentAHT: number;
}

const GrowthFactorDialog: React.FC<GrowthFactorDialogProps> = ({
  isOpen,
  onClose,
  onApply,
  currentForecastData,
  skills = []
}) => {
  // Default to 2 months ago to 1 month ahead
  const defaultStartDate = startOfMonth(addMonths(new Date(), -2));
  const defaultEndDate = endOfMonth(addMonths(new Date(), 1));

  const [config, setConfig] = useState<GrowthFactorConfig>({
    period: {
      start: defaultStartDate,
      end: defaultEndDate
    },
    growthType: 'percentage',
    growthValue: 400, // 400% = 5x growth (from 1,000 to 5,000)
    applyTo: 'volume',
    volumeGrowth: 400,
    ahtGrowth: 0,
    maintainDistribution: true,
    skillDistribution: {},
    compoundGrowth: false,
    growthPattern: 'linear'
  });

  const [showAdvanced, setShowAdvanced] = useState(false);
  const [previewData, setPreviewData] = useState<any>(null);

  // Initialize skill distribution
  useEffect(() => {
    if (skills.length > 0 && Object.keys(config.skillDistribution || {}).length === 0) {
      const totalVolume = skills.reduce((sum, skill) => sum + skill.currentVolume, 0);
      const distribution: { [skillId: string]: number } = {};
      
      skills.forEach(skill => {
        distribution[skill.id] = (skill.currentVolume / totalVolume) * 100;
      });
      
      setConfig(prev => ({ ...prev, skillDistribution: distribution }));
    }
  }, [skills]);

  // Calculate preview data
  useEffect(() => {
    calculatePreview();
  }, [config, currentForecastData]);

  const calculatePreview = () => {
    if (!currentForecastData) {
      // Generate sample data for demo
      const months = 6;
      const baseVolume = 1000;
      const baseAHT = 300;
      
      const originalData = Array.from({ length: months }, (_, i) => ({
        month: format(addMonths(config.period.start, i), 'MMM yyyy'),
        volume: baseVolume + (Math.random() * 200 - 100),
        aht: baseAHT + (Math.random() * 30 - 15)
      }));

      const scaledData = originalData.map((point, index) => {
        let volumeMultiplier = 1;
        let ahtMultiplier = 1;

        if (config.growthType === 'percentage') {
          volumeMultiplier = 1 + (config.volumeGrowth / 100);
          ahtMultiplier = 1 + (config.ahtGrowth / 100);
        } else {
          volumeMultiplier = (point.volume + config.volumeGrowth) / point.volume;
          ahtMultiplier = (point.aht + config.ahtGrowth) / point.aht;
        }

        // Apply growth pattern
        if (config.growthPattern === 'exponential') {
          const progress = index / (months - 1);
          volumeMultiplier = 1 + (volumeMultiplier - 1) * Math.pow(progress, 2);
        } else if (config.growthPattern === 'seasonal') {
          const seasonalFactor = 1 + 0.2 * Math.sin(index * Math.PI / 3);
          volumeMultiplier *= seasonalFactor;
        }

        return {
          month: point.month,
          volume: config.applyTo !== 'aht' ? point.volume * volumeMultiplier : point.volume,
          aht: config.applyTo !== 'volume' ? point.aht * ahtMultiplier : point.aht
        };
      });

      setPreviewData({ original: originalData, scaled: scaledData });
    }
  };

  const getGrowthMultiplier = () => {
    if (config.growthType === 'percentage') {
      return 1 + (config.volumeGrowth / 100);
    }
    return config.growthValue;
  };

  const getGrowthDescription = () => {
    const multiplier = getGrowthMultiplier();
    const fromValue = 1000;
    const toValue = Math.round(fromValue * multiplier);
    
    return `Scale from ${fromValue.toLocaleString()} to ${toValue.toLocaleString()} calls`;
  };

  const handleSkillDistributionChange = (skillId: string, value: number) => {
    const newDistribution = { ...config.skillDistribution };
    newDistribution[skillId] = value;
    
    // Normalize to 100%
    const total = Object.values(newDistribution).reduce((sum, val) => sum + val, 0);
    if (total > 100) {
      const scale = 100 / total;
      Object.keys(newDistribution).forEach(key => {
        newDistribution[key] *= scale;
      });
    }
    
    setConfig(prev => ({ ...prev, skillDistribution: newDistribution }));
  };

  const handleApply = () => {
    onApply(config);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="bg-blue-600 text-white p-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold flex items-center gap-2">
                📈 Growth Factor Configuration
              </h2>
              <p className="text-blue-100 mt-1">
                Scale your forecast volumes for capacity planning
              </p>
            </div>
            <button
              onClick={onClose}
              className="text-white hover:text-blue-200 transition"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto max-h-[calc(90vh-200px)]">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Left Column - Configuration */}
            <div className="space-y-6">
              {/* Period Selection */}
              <div className="bg-gray-50 p-4 rounded-lg">
                <h3 className="font-semibold mb-3 flex items-center gap-2">
                  📅 Application Period
                </h3>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Start Date
                    </label>
                    <input
                      type="date"
                      value={format(config.period.start, 'yyyy-MM-dd')}
                      onChange={(e) => setConfig(prev => ({
                        ...prev,
                        period: { ...prev.period, start: new Date(e.target.value) }
                      }))}
                      className="w-full border rounded-lg px-3 py-2"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      End Date
                    </label>
                    <input
                      type="date"
                      value={format(config.period.end, 'yyyy-MM-dd')}
                      onChange={(e) => setConfig(prev => ({
                        ...prev,
                        period: { ...prev.period, end: new Date(e.target.value) }
                      }))}
                      className="w-full border rounded-lg px-3 py-2"
                    />
                  </div>
                </div>
              </div>

              {/* Growth Configuration */}
              <div className="bg-gray-50 p-4 rounded-lg">
                <h3 className="font-semibold mb-3 flex items-center gap-2">
                  🎯 Growth Parameters
                </h3>
                
                {/* Growth Type */}
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Growth Type
                  </label>
                  <div className="flex gap-3">
                    <label className="flex items-center">
                      <input
                        type="radio"
                        value="percentage"
                        checked={config.growthType === 'percentage'}
                        onChange={(e) => setConfig(prev => ({ ...prev, growthType: 'percentage' }))}
                        className="mr-2"
                      />
                      Percentage
                    </label>
                    <label className="flex items-center">
                      <input
                        type="radio"
                        value="absolute"
                        checked={config.growthType === 'absolute'}
                        onChange={(e) => setConfig(prev => ({ ...prev, growthType: 'absolute' }))}
                        className="mr-2"
                      />
                      Absolute
                    </label>
                  </div>
                </div>

                {/* Apply To */}
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Apply Growth To
                  </label>
                  <select
                    value={config.applyTo}
                    onChange={(e) => setConfig(prev => ({ ...prev, applyTo: e.target.value as any }))}
                    className="w-full border rounded-lg px-3 py-2"
                  >
                    <option value="volume">Call Volume Only</option>
                    <option value="both">Both Volume and AHT</option>
                    <option value="aht">AHT Only</option>
                  </select>
                </div>

                {/* Volume Growth */}
                {config.applyTo !== 'aht' && (
                  <div className="mb-4">
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Volume Growth {config.growthType === 'percentage' ? '(%)' : '(calls)'}
                    </label>
                    <input
                      type="number"
                      value={config.volumeGrowth}
                      onChange={(e) => setConfig(prev => ({ ...prev, volumeGrowth: Number(e.target.value) }))}
                      className="w-full border rounded-lg px-3 py-2"
                      min="0"
                      step={config.growthType === 'percentage' ? '10' : '100'}
                    />
                    <p className="text-xs text-gray-500 mt-1">
                      {config.growthType === 'percentage' 
                        ? `Enter 400 for 5x growth (1,000 → 5,000 calls)`
                        : `Add ${config.volumeGrowth} calls to each interval`}
                    </p>
                  </div>
                )}

                {/* AHT Growth */}
                {config.applyTo !== 'volume' && (
                  <div className="mb-4">
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      AHT Growth {config.growthType === 'percentage' ? '(%)' : '(seconds)'}
                    </label>
                    <input
                      type="number"
                      value={config.ahtGrowth}
                      onChange={(e) => setConfig(prev => ({ ...prev, ahtGrowth: Number(e.target.value) }))}
                      className="w-full border rounded-lg px-3 py-2"
                      min="-100"
                      step={config.growthType === 'percentage' ? '5' : '10'}
                    />
                    <p className="text-xs text-gray-500 mt-1">
                      {config.growthType === 'percentage' 
                        ? `Positive values increase AHT, negative values decrease`
                        : `Add/subtract seconds from AHT`}
                    </p>
                  </div>
                )}

                {/* Growth Pattern */}
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Growth Pattern
                  </label>
                  <select
                    value={config.growthPattern}
                    onChange={(e) => setConfig(prev => ({ ...prev, growthPattern: e.target.value as any }))}
                    className="w-full border rounded-lg px-3 py-2"
                  >
                    <option value="linear">Linear (Constant)</option>
                    <option value="exponential">Exponential (Accelerating)</option>
                    <option value="seasonal">Seasonal (Varying)</option>
                  </select>
                </div>
              </div>

              {/* Advanced Options */}
              <div className="bg-gray-50 p-4 rounded-lg">
                <button
                  onClick={() => setShowAdvanced(!showAdvanced)}
                  className="w-full flex items-center justify-between font-semibold"
                >
                  <span className="flex items-center gap-2">
                    ⚙️ Advanced Options
                  </span>
                  <svg
                    className={`w-4 h-4 transform transition ${showAdvanced ? 'rotate-180' : ''}`}
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </button>

                {showAdvanced && (
                  <div className="mt-4 space-y-4">
                    {/* Maintain Distribution */}
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={config.maintainDistribution}
                        onChange={(e) => setConfig(prev => ({ ...prev, maintainDistribution: e.target.checked }))}
                        className="rounded"
                      />
                      <span className="text-sm">Maintain current distribution patterns</span>
                    </label>

                    {/* Compound Growth */}
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={config.compoundGrowth}
                        onChange={(e) => setConfig(prev => ({ ...prev, compoundGrowth: e.target.checked }))}
                        className="rounded"
                      />
                      <span className="text-sm">Apply compound growth</span>
                    </label>

                    {/* Multi-Skill Distribution */}
                    {skills.length > 0 && (
                      <div>
                        <h4 className="text-sm font-medium mb-2">Skill Distribution (%)</h4>
                        <div className="space-y-2">
                          {skills.map(skill => (
                            <div key={skill.id} className="flex items-center gap-2">
                              <span className="text-sm w-32">{skill.name}:</span>
                              <input
                                type="number"
                                value={config.skillDistribution?.[skill.id] || 0}
                                onChange={(e) => handleSkillDistributionChange(skill.id, Number(e.target.value))}
                                className="w-20 border rounded px-2 py-1 text-sm"
                                min="0"
                                max="100"
                                step="1"
                              />
                              <span className="text-sm">%</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* Right Column - Preview */}
            <div className="space-y-6">
              {/* Growth Summary */}
              <div className="bg-blue-50 p-4 rounded-lg">
                <h3 className="font-semibold mb-3 flex items-center gap-2 text-blue-900">
                  📊 Growth Summary
                </h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600">Growth Multiplier:</span>
                    <span className="font-semibold text-blue-900">
                      {getGrowthMultiplier().toFixed(1)}x
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Volume Impact:</span>
                    <span className="font-semibold text-blue-900">
                      {getGrowthDescription()}
                    </span>
                  </div>
                  {config.applyTo !== 'volume' && (
                    <div className="flex justify-between">
                      <span className="text-gray-600">AHT Change:</span>
                      <span className="font-semibold text-blue-900">
                        {config.ahtGrowth > 0 ? '+' : ''}{config.ahtGrowth}{config.growthType === 'percentage' ? '%' : 's'}
                      </span>
                    </div>
                  )}
                </div>
              </div>

              {/* Preview Chart */}
              <div className="bg-white border rounded-lg p-4">
                <h3 className="font-semibold mb-3">📈 Visual Preview</h3>
                {previewData && (
                  <div className="h-64">
                    <Line
                      data={{
                        labels: previewData.original.map((d: any) => d.month),
                        datasets: [
                          {
                            label: 'Original Volume',
                            data: previewData.original.map((d: any) => d.volume),
                            borderColor: 'rgb(59, 130, 246)',
                            backgroundColor: 'rgba(59, 130, 246, 0.1)',
                            borderWidth: 2,
                            tension: 0.3
                          },
                          {
                            label: 'Scaled Volume',
                            data: previewData.scaled.map((d: any) => d.volume),
                            borderColor: 'rgb(34, 197, 94)',
                            backgroundColor: 'rgba(34, 197, 94, 0.1)',
                            borderWidth: 2,
                            borderDash: [5, 5],
                            tension: 0.3
                          }
                        ]
                      }}
                      options={{
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                          legend: {
                            position: 'top' as const,
                          },
                          title: {
                            display: false
                          }
                        },
                        scales: {
                          y: {
                            beginAtZero: true,
                            title: {
                              display: true,
                              text: 'Call Volume'
                            }
                          }
                        }
                      }}
                    />
                  </div>
                )}
              </div>

              {/* Impact Analysis */}
              <div className="bg-yellow-50 p-4 rounded-lg">
                <h3 className="font-semibold mb-3 flex items-center gap-2 text-yellow-900">
                  ⚡ Impact Analysis
                </h3>
                <div className="space-y-2 text-sm text-yellow-800">
                  <p>• Required operators will increase proportionally</p>
                  <p>• Service level targets remain unchanged</p>
                  <p>• Schedule requirements will be recalculated</p>
                  {config.applyTo === 'both' && (
                    <p>• AHT changes will affect operator efficiency</p>
                  )}
                  {skills.length > 1 && (
                    <p>• Multi-skill distribution will be applied</p>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="bg-gray-50 px-6 py-4 border-t flex justify-between items-center">
          <div className="text-sm text-gray-600">
            💡 Tip: Use 400% growth to demonstrate scaling from 1,000 to 5,000 calls
          </div>
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-700 hover:text-gray-900 transition"
            >
              Cancel
            </button>
            <button
              onClick={handleApply}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-sm"
            >
              Apply Growth Factor
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default GrowthFactorDialog;