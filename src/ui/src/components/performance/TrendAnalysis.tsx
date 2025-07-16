import React, { useState, useEffect } from 'react';
import { 
  TrendingUp,
  TrendingDown, 
  BarChart3, 
  LineChart,
  AlertTriangle, 
  CheckCircle, 
  RefreshCw,
  Calendar,
  Target,
  Activity,
  Zap,
  Filter
} from 'lucide-react';
import realForecastingService, { ForecastDataPoint, AccuracyMetrics, AlgorithmOption } from '../../services/realForecastingService';

// Performance Component 5: Trend Analysis using GET /api/v1/forecasting/calculate
// This component analyzes performance trends with forecasting and predictive analytics

interface TrendMetric {
  id: string;
  name: string;
  current: number;
  predicted: number;
  change: number;
  trend: 'up' | 'down' | 'stable';
  confidence: number;
  unit: string;
  description: string;
}

interface TrendPeriod {
  label: string;
  value: string;
  days: number;
}

const TrendAnalysis: React.FC = () => {
  const [forecastData, setForecastData] = useState<ForecastDataPoint[]>([]);
  const [trendMetrics, setTrendMetrics] = useState<TrendMetric[]>([]);
  const [accuracyMetrics, setAccuracyMetrics] = useState<AccuracyMetrics | null>(null);
  const [algorithms, setAlgorithms] = useState<AlgorithmOption[]>([]);
  const [selectedAlgorithm, setSelectedAlgorithm] = useState('enhanced-arima');
  const [selectedPeriod, setSelectedPeriod] = useState('7d');
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [apiError, setApiError] = useState<string>('');
  const [autoRefresh, setAutoRefresh] = useState(true);

  const trendPeriods: TrendPeriod[] = [
    { label: '7 Days', value: '7d', days: 7 },
    { label: '14 Days', value: '14d', days: 14 },
    { label: '30 Days', value: '30d', days: 30 },
    { label: '90 Days', value: '90d', days: 90 }
  ];

  // Load initial data
  useEffect(() => {
    loadTrendData();
    loadAlgorithms();
    loadAccuracyMetrics();
  }, [selectedAlgorithm, selectedPeriod]);

  const loadTrendData = async () => {
    setApiError('');
    
    try {
      // Check API health first
      const healthCheck = await realForecastingService.checkApiHealth();
      if (!healthCheck.healthy) {
        throw new Error('Forecasting API is not available. Please try again later.');
      }

      const selectedPeriodData = trendPeriods.find(p => p.value === selectedPeriod);
      if (!selectedPeriodData) return;

      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(endDate.getDate() - selectedPeriodData.days);

      // Make real API call to GET /api/v1/forecasting/calculate
      const result = await realForecastingService.getCurrentForecast(
        startDate.toISOString().split('T')[0],
        endDate.toISOString().split('T')[0],
        selectedAlgorithm
      );
      
      if (result.success && result.data) {
        console.log('[TREND ANALYSIS] Forecast data loaded:', result.data);
        setForecastData(result.data);
        
        // Transform forecast data into trend metrics
        const metrics = transformToTrendMetrics(result.data);
        setTrendMetrics(metrics);
        
        setLastUpdate(new Date());
      } else {
        setApiError(result.error || 'Failed to load trend analysis data');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[TREND ANALYSIS] Forecast load error:', errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  const loadAlgorithms = async () => {
    try {
      const result = await realForecastingService.getAvailableAlgorithms();
      if (result.success && result.algorithms) {
        setAlgorithms(result.algorithms);
      }
    } catch (error) {
      console.warn('[TREND ANALYSIS] Failed to load algorithms:', error);
    }
  };

  const loadAccuracyMetrics = async () => {
    try {
      const result = await realForecastingService.getAccuracyMetrics(selectedAlgorithm);
      if (result.success && result.metrics) {
        setAccuracyMetrics(result.metrics);
      }
    } catch (error) {
      console.warn('[TREND ANALYSIS] Failed to load accuracy metrics:', error);
    }
  };

  // Transform forecast data into trend metrics
  const transformToTrendMetrics = (data: ForecastDataPoint[]): TrendMetric[] => {
    if (data.length === 0) return [];

    const metrics: TrendMetric[] = [];
    
    // Volume Trend
    const currentVolume = data[data.length - 1]?.predicted || 0;
    const avgPreviousVolume = data.slice(0, -1).reduce((sum, d) => sum + d.predicted, 0) / (data.length - 1);
    const volumeChange = ((currentVolume - avgPreviousVolume) / avgPreviousVolume) * 100;
    
    metrics.push({
      id: 'volume_trend',
      name: 'Call Volume Trend',
      current: currentVolume,
      predicted: currentVolume * 1.05, // 5% growth prediction
      change: volumeChange,
      trend: volumeChange > 0 ? 'up' : volumeChange < 0 ? 'down' : 'stable',
      confidence: data[data.length - 1]?.confidence || 85,
      unit: 'calls',
      description: 'Predicted call volume trend based on historical patterns'
    });

    // Agent Requirement Trend
    const currentAgents = data[data.length - 1]?.requiredAgents || 0;
    const avgPreviousAgents = data.slice(0, -1).reduce((sum, d) => sum + d.requiredAgents, 0) / (data.length - 1);
    const agentsChange = ((currentAgents - avgPreviousAgents) / avgPreviousAgents) * 100;
    
    metrics.push({
      id: 'agents_trend',
      name: 'Agent Requirement Trend',
      current: currentAgents,
      predicted: Math.ceil(currentAgents * 1.03), // 3% increase prediction
      change: agentsChange,
      trend: agentsChange > 0 ? 'up' : agentsChange < 0 ? 'down' : 'stable',
      confidence: data[data.length - 1]?.confidence || 80,
      unit: 'agents',
      description: 'Forecasted staffing requirements based on volume trends'
    });

    // Peak Performance Trend
    const peaks = data.filter(d => d.predicted > avgPreviousVolume * 1.2);
    const peakTrend = (peaks.length / data.length) * 100;
    
    metrics.push({
      id: 'peak_trend',
      name: 'Peak Activity Trend',
      current: peakTrend,
      predicted: peakTrend * 1.1,
      change: peakTrend > 20 ? 15 : -5,
      trend: peakTrend > 20 ? 'up' : 'down',
      confidence: 75,
      unit: '%',
      description: 'Frequency and intensity of peak activity periods'
    });

    // Efficiency Trend (inverse of agent to volume ratio)
    const efficiency = data.length > 0 ? (currentVolume / currentAgents) : 0;
    const avgEfficiency = data.reduce((sum, d) => sum + (d.predicted / d.requiredAgents), 0) / data.length;
    const efficiencyChange = ((efficiency - avgEfficiency) / avgEfficiency) * 100;
    
    metrics.push({
      id: 'efficiency_trend',
      name: 'Operational Efficiency',
      current: efficiency,
      predicted: efficiency * 1.08,
      change: efficiencyChange,
      trend: efficiencyChange > 0 ? 'up' : 'down',
      confidence: 85,
      unit: 'calls/agent',
      description: 'Agent productivity and operational efficiency metrics'
    });

    return metrics;
  };

  // Auto-refresh every 60 seconds
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(async () => {
      setIsUpdating(true);
      
      try {
        await loadTrendData();
        await loadAccuracyMetrics();
      } catch (error) {
        console.warn('[TREND ANALYSIS] Auto-refresh failed:', error);
      }
      
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 60000);

    return () => clearInterval(interval);
  }, [autoRefresh, selectedAlgorithm, selectedPeriod]);

  const getTrendColor = (trend: string, change: number) => {
    if (trend === 'up' && change > 0) return 'text-green-600 bg-green-100 border-green-200';
    if (trend === 'down' && change < 0) return 'text-red-600 bg-red-100 border-red-200';
    if (trend === 'up' && change < 0) return 'text-red-600 bg-red-100 border-red-200';
    if (trend === 'down' && change > 0) return 'text-green-600 bg-green-100 border-green-200';
    return 'text-gray-600 bg-gray-100 border-gray-200';
  };

  const getTrendIcon = (trend: string, change: number) => {
    if (trend === 'up') {
      return <TrendingUp className={`h-4 w-4 ${change > 0 ? 'text-green-500' : 'text-red-500'}`} />;
    } else if (trend === 'down') {
      return <TrendingDown className={`h-4 w-4 ${change < 0 ? 'text-red-500' : 'text-green-500'}`} />;
    }
    return <Activity className="h-4 w-4 text-gray-500" />;
  };

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 90) return 'text-green-600';
    if (confidence >= 75) return 'text-blue-600';
    if (confidence >= 60) return 'text-yellow-600';
    return 'text-red-600';
  };

  const formatValue = (value: number, unit: string) => {
    if (unit === '%') return `${value.toFixed(1)}%`;
    if (unit === 'calls' || unit === 'agents') return Math.round(value).toLocaleString();
    if (unit === 'calls/agent') return value.toFixed(2);
    return value.toLocaleString();
  };

  // Loading state
  if (isLoading) {
    return (
      <div className="p-6 space-y-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="animate-pulse">
            <div className="h-8 bg-gray-200 rounded w-1/3 mb-4"></div>
            <div className="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {[1,2,3,4].map((i) => (
            <div key={i} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 animate-pulse">
              <div className="h-32 bg-gray-200 rounded"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* API Error Display */}
      {apiError && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center gap-2 text-red-800">
            <AlertTriangle className="h-5 w-5 text-red-500" />
            <div>
              <div className="font-medium">Forecasting Service Error</div>
              <div className="text-sm">{apiError}</div>
            </div>
            <button
              onClick={loadTrendData}
              className="ml-auto px-3 py-1 bg-red-100 text-red-700 rounded text-sm hover:bg-red-200"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <LineChart className="h-6 w-6 mr-2 text-blue-600" />
              Performance Trend Analysis
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">📈</span>
              Advanced forecasting and trend analysis with predictive analytics
            </p>
          </div>
          
          <div className="text-right">
            <div className="flex items-center space-x-4">
              <select
                value={selectedPeriod}
                onChange={(e) => setSelectedPeriod(e.target.value)}
                className="px-3 py-1 border border-gray-300 rounded text-sm"
              >
                {trendPeriods.map(period => (
                  <option key={period.value} value={period.value}>{period.label}</option>
                ))}
              </select>
              <select
                value={selectedAlgorithm}
                onChange={(e) => setSelectedAlgorithm(e.target.value)}
                className="px-3 py-1 border border-gray-300 rounded text-sm"
              >
                {algorithms.map(algo => (
                  <option key={algo.id} value={algo.id} disabled={!algo.enabled}>
                    {algo.name} ({algo.accuracy.toFixed(1)}%)
                  </option>
                ))}
              </select>
              <button
                onClick={() => setAutoRefresh(!autoRefresh)}
                className={`flex items-center space-x-2 px-3 py-1 rounded text-sm transition-colors ${
                  autoRefresh ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
                }`}
              >
                <RefreshCw className={`h-4 w-4 ${isUpdating ? 'animate-spin' : ''}`} />
                <span>{autoRefresh ? 'Auto-refresh ON' : 'Auto-refresh OFF'}</span>
              </button>
              <div className={`flex items-center space-x-2 text-sm ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
                <div className={`w-2 h-2 rounded-full ${isUpdating ? 'bg-blue-500 animate-pulse' : 'bg-green-500'}`}></div>
                <span>Updated: {lastUpdate.toLocaleTimeString()}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Accuracy Metrics */}
      {accuracyMetrics && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
            <Target className="h-5 w-5 mr-2" />
            Forecast Accuracy ({selectedAlgorithm})
          </h3>
          
          <div className="grid grid-cols-1 md:grid-cols-5 gap-6">
            <div className="text-center">
              <div className={`text-2xl font-bold ${getConfidenceColor(accuracyMetrics.confidence)}`}>
                {accuracyMetrics.confidence.toFixed(1)}%
              </div>
              <div className="text-sm text-gray-600">Confidence</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                {accuracyMetrics.mape.toFixed(1)}%
              </div>
              <div className="text-sm text-gray-600">MAPE</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {accuracyMetrics.wape.toFixed(1)}%
              </div>
              <div className="text-sm text-gray-600">WAPE</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">
                {accuracyMetrics.mae.toFixed(0)}
              </div>
              <div className="text-sm text-gray-600">MAE</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">
                {accuracyMetrics.rmse.toFixed(0)}
              </div>
              <div className="text-sm text-gray-600">RMSE</div>
            </div>
          </div>
        </div>
      )}

      {/* Trend Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {trendMetrics.map((metric) => (
          <div 
            key={metric.id} 
            className={`bg-white rounded-lg shadow-sm border-2 p-6 ${getTrendColor(metric.trend, metric.change)}`}
          >
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-2">
                <BarChart3 className="h-6 w-6" />
                <h3 className="font-semibold text-gray-900">{metric.name}</h3>
              </div>
              {getTrendIcon(metric.trend, metric.change)}
            </div>
            
            <div className="mb-4">
              <div className="grid grid-cols-2 gap-4 mb-3">
                <div>
                  <div className="text-sm text-gray-600">Current</div>
                  <div className="text-2xl font-bold text-gray-900">
                    {formatValue(metric.current, metric.unit)}
                  </div>
                </div>
                <div>
                  <div className="text-sm text-gray-600">Predicted</div>
                  <div className="text-2xl font-bold text-blue-600">
                    {formatValue(metric.predicted, metric.unit)}
                  </div>
                </div>
              </div>
              
              {/* Trend Progress Bar */}
              <div className="w-full bg-gray-200 rounded-full h-2 mb-2">
                <div 
                  className={`h-2 rounded-full transition-all duration-300 ${
                    metric.change > 0 ? 'bg-green-500' : 'bg-red-500'
                  }`}
                  style={{ width: `${Math.min(Math.abs(metric.change) * 2, 100)}%` }}
                ></div>
              </div>
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className={`font-medium ${
                  metric.change > 0 ? 'text-green-600' : 
                  metric.change < 0 ? 'text-red-600' : 'text-gray-600'
                }`}>
                  {metric.change > 0 ? '+' : ''}{metric.change.toFixed(1)}% change
                </span>
                <span className={`px-2 py-1 rounded text-xs font-medium ${getConfidenceColor(metric.confidence)} bg-opacity-20`}>
                  {metric.confidence.toFixed(0)}% confidence
                </span>
              </div>
              <p className="text-xs text-gray-600">{metric.description}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Forecast Data Summary */}
      {forecastData.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
            <Calendar className="h-5 w-5 mr-2" />
            Forecast Data Summary ({forecastData.length} data points)
          </h3>
          
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div className="text-center p-4 bg-blue-50 rounded-lg">
              <Activity className="h-6 w-6 text-blue-600 mx-auto mb-2" />
              <div className="text-xl font-bold text-blue-600">
                {Math.round(forecastData.reduce((sum, d) => sum + d.predicted, 0) / forecastData.length)}
              </div>
              <div className="text-sm text-gray-600">Avg Predicted Volume</div>
            </div>
            
            <div className="text-center p-4 bg-green-50 rounded-lg">
              <Target className="h-6 w-6 text-green-600 mx-auto mb-2" />
              <div className="text-xl font-bold text-green-600">
                {Math.round(forecastData.reduce((sum, d) => sum + d.requiredAgents, 0) / forecastData.length)}
              </div>
              <div className="text-sm text-gray-600">Avg Required Agents</div>
            </div>
            
            <div className="text-center p-4 bg-purple-50 rounded-lg">
              <Zap className="h-6 w-6 text-purple-600 mx-auto mb-2" />
              <div className="text-xl font-bold text-purple-600">
                {Math.round(forecastData.reduce((sum, d) => sum + d.confidence, 0) / forecastData.length)}%
              </div>
              <div className="text-sm text-gray-600">Avg Confidence</div>
            </div>
            
            <div className="text-center p-4 bg-orange-50 rounded-lg">
              <Calendar className="h-6 w-6 text-orange-600 mx-auto mb-2" />
              <div className="text-xl font-bold text-orange-600">
                {forecastData.filter(d => d.isWeekend).length}
              </div>
              <div className="text-sm text-gray-600">Weekend Data Points</div>
            </div>
          </div>
        </div>
      )}

      {/* Status Bar */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
              <span className="text-sm text-gray-600">Trend analysis active</span>
            </div>
            <div className="text-sm text-gray-500">
              Algorithm: {selectedAlgorithm} | Period: {trendPeriods.find(p => p.value === selectedPeriod)?.label}
            </div>
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            <span>📊 {trendMetrics.length} Trends</span>
            <span>📈 {forecastData.length} Data Points</span>
            <span>🎯 {accuracyMetrics?.confidence.toFixed(0) || 0}% Accuracy</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TrendAnalysis;