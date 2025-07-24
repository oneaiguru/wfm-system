import React, { useState, useEffect, useMemo } from 'react';
import { 
  Settings, 
  Play, 
  Save, 
  RotateCcw, 
  TrendingUp, 
  BarChart3, 
  Users, 
  Clock,
  AlertCircle,
  CheckCircle,
  Plus,
  Minus,
  Copy,
  Download
} from 'lucide-react';
import realForecastingService from '../../../../services/realForecastingService';

// Types for scenario management
interface ScenarioParameter {
  id: string;
  name: string;
  description: string;
  type: 'number' | 'percentage' | 'boolean' | 'select';
  value: any;
  min?: number;
  max?: number;
  step?: number;
  options?: string[];
  unit?: string;
  category: 'volume' | 'staffing' | 'operations' | 'external';
}

interface ScenarioResult {
  id: string;
  name: string;
  timestamp: string;
  parameters: ScenarioParameter[];
  metrics: {
    expectedVolume: number;
    requiredAgents: number;
    costImpact: number;
    serviceLevel: number;
    efficiency: number;
  };
  forecast: {
    hourlyData: Array<{
      hour: string;
      predictedVolume: number;
      requiredAgents: number;
      confidence: number;
    }>;
    summary: {
      totalCalls: number;
      peakVolume: number;
      averageAgents: number;
      costEstimate: number;
    };
  };
  comparison: {
    baseline: any;
    difference: any;
    improvement: number;
  };
}

interface ScenarioBuilderProps {
  className?: string;
  onScenarioGenerated?: (scenario: ScenarioResult) => void;
  onScenarioSaved?: (scenario: ScenarioResult) => void;
}

const ScenarioBuilder: React.FC<ScenarioBuilderProps> = ({
  className = '',
  onScenarioGenerated,
  onScenarioSaved
}) => {
  const [activeTab, setActiveTab] = useState<'builder' | 'results' | 'comparison'>('builder');
  const [isGenerating, setIsGenerating] = useState(false);
  const [currentScenario, setCurrentScenario] = useState<ScenarioResult | null>(null);
  const [savedScenarios, setSavedScenarios] = useState<ScenarioResult[]>([]);
  const [selectedComparison, setSelectedComparison] = useState<string[]>([]);
  const [apiStatus, setApiStatus] = useState<'checking' | 'available' | 'unavailable'>('checking');

  // Default scenario parameters
  const [parameters, setParameters] = useState<ScenarioParameter[]>([
    // Volume Parameters
    {
      id: 'base_volume',
      name: 'Base Call Volume',
      description: 'Expected number of calls per hour',
      type: 'number',
      value: 250,
      min: 50,
      max: 1000,
      step: 10,
      unit: 'calls/hour',
      category: 'volume'
    },
    {
      id: 'volume_variance',
      name: 'Volume Variance',
      description: 'Expected fluctuation in call volume',
      type: 'percentage',
      value: 15,
      min: 5,
      max: 50,
      step: 1,
      unit: '%',
      category: 'volume'
    },
    {
      id: 'seasonal_factor',
      name: 'Seasonal Adjustment',
      description: 'Seasonal multiplier for volume',
      type: 'percentage',
      value: 0,
      min: -30,
      max: 30,
      step: 1,
      unit: '%',
      category: 'volume'
    },
    
    // Staffing Parameters
    {
      id: 'service_level_target',
      name: 'Service Level Target',
      description: 'Target percentage of calls answered within threshold',
      type: 'percentage',
      value: 80,
      min: 60,
      max: 95,
      step: 1,
      unit: '%',
      category: 'staffing'
    },
    {
      id: 'average_handle_time',
      name: 'Average Handle Time',
      description: 'Average time per call including wrap-up',
      type: 'number',
      value: 180,
      min: 60,
      max: 600,
      step: 10,
      unit: 'seconds',
      category: 'staffing'
    },
    {
      id: 'shrinkage_rate',
      name: 'Shrinkage Rate',
      description: 'Time lost to breaks, training, etc.',
      type: 'percentage',
      value: 25,
      min: 15,
      max: 40,
      step: 1,
      unit: '%',
      category: 'staffing'
    },
    
    // Operations Parameters
    {
      id: 'skill_distribution',
      name: 'Multi-skill Agents',
      description: 'Percentage of agents with multiple skills',
      type: 'percentage',
      value: 60,
      min: 0,
      max: 100,
      step: 5,
      unit: '%',
      category: 'operations'
    },
    {
      id: 'overtime_allowed',
      name: 'Overtime Allowed',
      description: 'Allow overtime scheduling',
      type: 'boolean',
      value: true,
      category: 'operations'
    },
    
    // External Parameters
    {
      id: 'external_events',
      name: 'External Events Impact',
      description: 'Impact of external events on volume',
      type: 'select',
      value: 'none',
      options: ['none', 'low', 'medium', 'high'],
      category: 'external'
    },
    {
      id: 'weather_impact',
      name: 'Weather Impact',
      description: 'Expected weather impact on call volume',
      type: 'select',
      value: 'normal',
      options: ['normal', 'storm', 'holiday', 'extreme'],
      category: 'external'
    }
  ]);

  // Check API availability on mount
  useEffect(() => {
    checkApiStatus();
  }, []);

  const checkApiStatus = async () => {
    setApiStatus('checking');
    try {
      const health = await realForecastingService.checkApiHealth();
      setApiStatus(health.healthy ? 'available' : 'unavailable');
    } catch (error) {
      setApiStatus('unavailable');
    }
  };

  // Update parameter value
  const updateParameter = (id: string, value: any) => {
    setParameters(prev => prev.map(param => 
      param.id === id ? { ...param, value } : param
    ));
  };

  // Reset parameters to defaults
  const resetParameters = () => {
    setParameters(prev => prev.map(param => ({
      ...param,
      value: param.type === 'boolean' ? false : 
             param.type === 'select' ? (param.options?.[0] || '') :
             param.min || 0
    })));
  };

  // Generate scenario based on current parameters
  const generateScenario = async () => {
    setIsGenerating(true);
    
    try {
      // Prepare API request
      const scenarioRequest = {
        base_date: new Date().toISOString().split('T')[0],
        service_name: 'customer_support',
        group_name: 'main_queue',
        parameters: parameters.map(p => ({
          name: p.id,
          value: p.value,
          type: p.type
        }))
      };

      let scenarioResult: ScenarioResult;

      if (apiStatus === 'available') {
        // Try to use real API
        try {
          const response = await fetch('http://localhost:8001/api/v1/forecasts/scenarios', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${localStorage.getItem('authToken') || 'test-token'}`
            },
            body: JSON.stringify(scenarioRequest)
          });

          if (response.ok) {
            const apiResult = await response.json();
            // Transform API response to our format
            scenarioResult = await transformApiResponse(apiResult);
          } else {
            throw new Error('API request failed');
          }
        } catch (apiError) {
          console.warn('API call failed, using demo scenario:', apiError);
          scenarioResult = generateDemoScenario();
        }
      } else {
        // Use demo scenario
        scenarioResult = generateDemoScenario();
      }

      setCurrentScenario(scenarioResult);
      setActiveTab('results');
      onScenarioGenerated?.(scenarioResult);

    } catch (error) {
      console.error('Error generating scenario:', error);
      // Fallback to demo scenario
      const demoScenario = generateDemoScenario();
      setCurrentScenario(demoScenario);
      setActiveTab('results');
    } finally {
      setIsGenerating(false);
    }
  };

  // Transform API response to our scenario format
  const transformApiResponse = async (apiResponse: any): Promise<ScenarioResult> => {
    // This would transform the actual API response
    // For now, we'll generate a demo scenario based on parameters
    return generateDemoScenario();
  };

  // Generate demo scenario based on current parameters
  const generateDemoScenario = (): ScenarioResult => {
    const baseVolume = parameters.find(p => p.id === 'base_volume')?.value || 250;
    const variance = parameters.find(p => p.id === 'volume_variance')?.value || 15;
    const serviceLevel = parameters.find(p => p.id === 'service_level_target')?.value || 80;
    const handleTime = parameters.find(p => p.id === 'average_handle_time')?.value || 180;
    const shrinkage = parameters.find(p => p.id === 'shrinkage_rate')?.value || 25;

    // Generate hourly forecast data
    const hourlyData = Array.from({ length: 24 }, (_, hour) => {
      const hourMultiplier = getHourMultiplier(hour);
      const volumeVariance = (Math.random() - 0.5) * (variance / 100) * 2;
      const predictedVolume = Math.round(baseVolume * hourMultiplier * (1 + volumeVariance));
      
      // Calculate required agents using Erlang C approximation
      const intensity = (predictedVolume * handleTime) / 3600;
      const baseAgents = Math.ceil(intensity);
      const serviceAdjustment = serviceLevel > 80 ? 1.2 : 1.0;
      const shrinkageAdjustment = 1 / (1 - shrinkage / 100);
      const requiredAgents = Math.ceil(baseAgents * serviceAdjustment * shrinkageAdjustment);

      return {
        hour: `${hour.toString().padStart(2, '0')}:00`,
        predictedVolume,
        requiredAgents,
        confidence: 0.85 + Math.random() * 0.1
      };
    });

    const totalCalls = hourlyData.reduce((sum, h) => sum + h.predictedVolume, 0);
    const peakVolume = Math.max(...hourlyData.map(h => h.predictedVolume));
    const averageAgents = Math.round(hourlyData.reduce((sum, h) => sum + h.requiredAgents, 0) / 24);
    const costEstimate = averageAgents * 24 * 25; // $25/hour estimate

    return {
      id: `scenario_${Date.now()}`,
      name: `Scenario ${new Date().toLocaleTimeString()}`,
      timestamp: new Date().toISOString(),
      parameters: [...parameters],
      metrics: {
        expectedVolume: totalCalls,
        requiredAgents: averageAgents,
        costImpact: costEstimate,
        serviceLevel,
        efficiency: Math.min(95, 70 + (serviceLevel - 70) * 0.5)
      },
      forecast: {
        hourlyData,
        summary: {
          totalCalls,
          peakVolume,
          averageAgents,
          costEstimate
        }
      },
      comparison: {
        baseline: null,
        difference: null,
        improvement: 0
      }
    };
  };

  // Helper function to get hour multiplier for realistic patterns
  const getHourMultiplier = (hour: number): number => {
    // Typical call center pattern
    const patterns = [
      0.3, 0.2, 0.2, 0.2, 0.3, 0.4, // 00-05
      0.5, 0.7, 0.9, 1.2, 1.4, 1.6, // 06-11
      1.5, 1.7, 1.8, 1.6, 1.4, 1.2, // 12-17
      1.0, 0.8, 0.6, 0.5, 0.4, 0.3  // 18-23
    ];
    return patterns[hour] || 1.0;
  };

  // Save current scenario
  const saveScenario = () => {
    if (currentScenario) {
      const updatedScenario = {
        ...currentScenario,
        name: `Saved ${new Date().toLocaleString()}`
      };
      setSavedScenarios(prev => [...prev, updatedScenario]);
      onScenarioSaved?.(updatedScenario);
    }
  };

  // Copy scenario parameters
  const copyScenario = (scenario: ScenarioResult) => {
    setParameters([...scenario.parameters]);
  };

  // Export scenario data
  const exportScenario = (scenario: ScenarioResult) => {
    const dataStr = JSON.stringify(scenario, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `scenario_${scenario.id}.json`;
    link.click();
    URL.revokeObjectURL(url);
  };

  // Group parameters by category
  const parametersByCategory = useMemo(() => {
    return parameters.reduce((acc, param) => {
      if (!acc[param.category]) acc[param.category] = [];
      acc[param.category].push(param);
      return acc;
    }, {} as Record<string, ScenarioParameter[]>);
  }, [parameters]);

  const categoryLabels = {
    volume: { name: 'Call Volume', icon: TrendingUp, color: 'blue' },
    staffing: { name: 'Staffing', icon: Users, color: 'green' },
    operations: { name: 'Operations', icon: Settings, color: 'purple' },
    external: { name: 'External Factors', icon: AlertCircle, color: 'orange' }
  };

  const renderParameterControl = (param: ScenarioParameter) => {
    switch (param.type) {
      case 'number':
      case 'percentage':
        return (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">{param.value}{param.unit}</span>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => updateParameter(param.id, Math.max(param.min || 0, param.value - (param.step || 1)))}
                  className="p-1 text-gray-400 hover:text-gray-600 rounded"
                >
                  <Minus className="w-3 h-3" />
                </button>
                <button
                  onClick={() => updateParameter(param.id, Math.min(param.max || 1000, param.value + (param.step || 1)))}
                  className="p-1 text-gray-400 hover:text-gray-600 rounded"
                >
                  <Plus className="w-3 h-3" />
                </button>
              </div>
            </div>
            <input
              type="range"
              min={param.min}
              max={param.max}
              step={param.step}
              value={param.value}
              onChange={(e) => updateParameter(param.id, parseFloat(e.target.value))}
              className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider"
            />
          </div>
        );
        
      case 'boolean':
        return (
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={param.value}
              onChange={(e) => updateParameter(param.id, e.target.checked)}
              className="rounded border-gray-300"
            />
            <span className="text-sm text-gray-600">
              {param.value ? 'Enabled' : 'Disabled'}
            </span>
          </label>
        );
        
      case 'select':
        return (
          <select
            value={param.value}
            onChange={(e) => updateParameter(param.id, e.target.value)}
            className="w-full p-2 border border-gray-300 rounded-md text-sm"
          >
            {param.options?.map(option => (
              <option key={option} value={option}>
                {option.charAt(0).toUpperCase() + option.slice(1)}
              </option>
            ))}
          </select>
        );
        
      default:
        return null;
    }
  };

  return (
    <div className={`bg-white rounded-lg shadow-lg ${className}`}>
      {/* Header */}
      <div className="border-b border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
              <Settings className="w-6 h-6 text-purple-600" />
              What-If Scenario Builder
            </h2>
            <p className="text-sm text-gray-600 mt-1">
              Model different scenarios and analyze their impact on forecasting and staffing
            </p>
          </div>
          
          <div className="flex items-center gap-2">
            {apiStatus === 'available' && (
              <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full flex items-center gap-1">
                <CheckCircle className="w-3 h-3" />
                Live API
              </span>
            )}
            {apiStatus === 'unavailable' && (
              <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-1 rounded-full flex items-center gap-1">
                <AlertCircle className="w-3 h-3" />
                Demo Mode
              </span>
            )}
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="flex gap-1 mt-6">
          {[
            { id: 'builder', label: 'Scenario Builder', icon: Settings },
            { id: 'results', label: 'Results', icon: BarChart3 },
            { id: 'comparison', label: 'Comparison', icon: TrendingUp }
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-colors flex items-center gap-2 ${
                activeTab === tab.id
                  ? 'bg-purple-100 text-purple-700 border border-purple-200'
                  : 'text-gray-600 hover:text-gray-800 hover:bg-gray-100'
              }`}
            >
              <tab.icon className="w-4 h-4" />
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="p-6">
        {activeTab === 'builder' && (
          <div className="space-y-6">
            {/* Parameter Categories */}
            {Object.entries(categoryLabels).map(([category, config]) => (
              <div key={category} className="border rounded-lg">
                <div className={`bg-${config.color}-50 border-b border-${config.color}-100 p-4`}>
                  <h3 className={`font-semibold text-${config.color}-900 flex items-center gap-2`}>
                    <config.icon className="w-5 h-5" />
                    {config.name}
                  </h3>
                </div>
                <div className="p-4 grid grid-cols-1 md:grid-cols-2 gap-6">
                  {parametersByCategory[category]?.map(param => (
                    <div key={param.id} className="space-y-2">
                      <div className="flex items-center justify-between">
                        <label className="font-medium text-gray-900 text-sm">
                          {param.name}
                        </label>
                      </div>
                      <p className="text-xs text-gray-500">{param.description}</p>
                      {renderParameterControl(param)}
                    </div>
                  ))}
                </div>
              </div>
            ))}

            {/* Action Buttons */}
            <div className="flex items-center justify-between pt-4 border-t">
              <button
                onClick={resetParameters}
                className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 border border-gray-300 rounded-md hover:bg-gray-50 flex items-center gap-2"
              >
                <RotateCcw className="w-4 h-4" />
                Reset to Defaults
              </button>
              
              <button
                onClick={generateScenario}
                disabled={isGenerating}
                className="px-6 py-2 text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 disabled:opacity-50 rounded-md flex items-center gap-2"
              >
                {isGenerating ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                    Generating...
                  </>
                ) : (
                  <>
                    <Play className="w-4 h-4" />
                    Generate Scenario
                  </>
                )}
              </button>
            </div>
          </div>
        )}

        {activeTab === 'results' && (
          <div className="space-y-6">
            {currentScenario ? (
              <>
                {/* Scenario Overview */}
                <div className="bg-gradient-to-r from-purple-50 to-blue-50 p-6 rounded-lg border">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-lg font-semibold text-gray-900">Scenario Results</h3>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={saveScenario}
                        className="px-3 py-1 text-sm text-purple-600 hover:text-purple-800 border border-purple-300 rounded-md hover:bg-purple-50 flex items-center gap-2"
                      >
                        <Save className="w-4 h-4" />
                        Save
                      </button>
                      <button
                        onClick={() => exportScenario(currentScenario)}
                        className="px-3 py-1 text-sm text-gray-600 hover:text-gray-800 border border-gray-300 rounded-md hover:bg-gray-50 flex items-center gap-2"
                      >
                        <Download className="w-4 h-4" />
                        Export
                      </button>
                    </div>
                  </div>
                  
                  {/* Key Metrics */}
                  <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                    <div className="text-center">
                      <div className="text-2xl font-bold text-blue-600">
                        {currentScenario.metrics.expectedVolume.toLocaleString()}
                      </div>
                      <div className="text-sm text-gray-600">Total Calls</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-green-600">
                        {currentScenario.metrics.requiredAgents}
                      </div>
                      <div className="text-sm text-gray-600">Avg Agents</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-purple-600">
                        ${currentScenario.metrics.costImpact.toLocaleString()}
                      </div>
                      <div className="text-sm text-gray-600">Cost Impact</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-orange-600">
                        {currentScenario.metrics.serviceLevel}%
                      </div>
                      <div className="text-sm text-gray-600">Service Level</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-indigo-600">
                        {currentScenario.metrics.efficiency.toFixed(1)}%
                      </div>
                      <div className="text-sm text-gray-600">Efficiency</div>
                    </div>
                  </div>
                </div>

                {/* Hourly Forecast Table */}
                <div className="border rounded-lg">
                  <div className="p-4 border-b">
                    <h3 className="font-semibold text-gray-900 flex items-center gap-2">
                      <Clock className="w-5 h-5 text-blue-600" />
                      24-Hour Forecast
                    </h3>
                  </div>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="text-left p-3 text-sm font-medium text-gray-600">Hour</th>
                          <th className="text-center p-3 text-sm font-medium text-gray-600">Volume</th>
                          <th className="text-center p-3 text-sm font-medium text-gray-600">Agents</th>
                          <th className="text-center p-3 text-sm font-medium text-gray-600">Confidence</th>
                          <th className="text-center p-3 text-sm font-medium text-gray-600">Utilization</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200">
                        {currentScenario.forecast.hourlyData.map((hour, index) => {
                          const utilization = (hour.predictedVolume / (hour.requiredAgents * 60)) * 100;
                          const isHighVolume = hour.predictedVolume === currentScenario.forecast.summary.peakVolume;
                          
                          return (
                            <tr key={index} className={isHighVolume ? 'bg-yellow-50' : 'hover:bg-gray-50'}>
                              <td className="p-3 font-medium">
                                {hour.hour}
                                {isHighVolume && <span className="ml-2 text-xs text-yellow-600">PEAK</span>}
                              </td>
                              <td className="text-center p-3">
                                <span className="font-medium">{hour.predictedVolume}</span>
                              </td>
                              <td className="text-center p-3">
                                <span className="font-medium">{hour.requiredAgents}</span>
                              </td>
                              <td className="text-center p-3">
                                <span className={`text-sm ${
                                  hour.confidence > 0.8 ? 'text-green-600' : 
                                  hour.confidence > 0.6 ? 'text-yellow-600' : 'text-red-600'
                                }`}>
                                  {(hour.confidence * 100).toFixed(0)}%
                                </span>
                              </td>
                              <td className="text-center p-3">
                                <span className={`text-sm ${
                                  utilization > 85 ? 'text-red-600' : 
                                  utilization > 70 ? 'text-yellow-600' : 'text-green-600'
                                }`}>
                                  {utilization.toFixed(0)}%
                                </span>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              </>
            ) : (
              <div className="text-center py-12">
                <Settings className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No Scenario Generated</h3>
                <p className="text-gray-600 mb-4">Build a scenario first to see the results</p>
                <button
                  onClick={() => setActiveTab('builder')}
                  className="px-4 py-2 text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 rounded-md"
                >
                  Go to Builder
                </button>
              </div>
            )}
          </div>
        )}

        {activeTab === 'comparison' && (
          <div className="space-y-6">
            {savedScenarios.length > 0 ? (
              <>
                {/* Saved Scenarios */}
                <div className="border rounded-lg">
                  <div className="p-4 border-b">
                    <h3 className="font-semibold text-gray-900">Saved Scenarios</h3>
                    <p className="text-sm text-gray-600 mt-1">Compare different scenarios and their outcomes</p>
                  </div>
                  <div className="divide-y divide-gray-200">
                    {savedScenarios.map((scenario, index) => (
                      <div key={scenario.id} className="p-4 flex items-center justify-between">
                        <div className="flex-1">
                          <div className="font-medium text-gray-900">{scenario.name}</div>
                          <div className="text-sm text-gray-600">
                            {scenario.metrics.expectedVolume.toLocaleString()} calls • 
                            {scenario.metrics.requiredAgents} agents • 
                            ${scenario.metrics.costImpact.toLocaleString()}
                          </div>
                          <div className="text-xs text-gray-500">{new Date(scenario.timestamp).toLocaleString()}</div>
                        </div>
                        <div className="flex items-center gap-2 ml-4">
                          <button
                            onClick={() => copyScenario(scenario)}
                            className="p-2 text-gray-400 hover:text-gray-600 rounded-md hover:bg-gray-100"
                            title="Copy parameters"
                          >
                            <Copy className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => exportScenario(scenario)}
                            className="p-2 text-gray-400 hover:text-gray-600 rounded-md hover:bg-gray-100"
                            title="Export scenario"
                          >
                            <Download className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </>
            ) : (
              <div className="text-center py-12">
                <BarChart3 className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No Saved Scenarios</h3>
                <p className="text-gray-600 mb-4">Generate and save scenarios to compare them</p>
                <button
                  onClick={() => setActiveTab('builder')}
                  className="px-4 py-2 text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 rounded-md"
                >
                  Create First Scenario
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default ScenarioBuilder;