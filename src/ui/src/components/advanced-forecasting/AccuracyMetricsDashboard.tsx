import React, { useState, useEffect } from 'react';
import { Target, TrendingUp, AlertCircle, CheckCircle, BarChart3, Download, RefreshCw, Calendar } from 'lucide-react';

interface AccuracyMetric {
  id: string;
  name: string;
  value: number;
  target: number;
  unit: string;
  description: string;
  trend: 'up' | 'down' | 'stable';
  status: 'good' | 'warning' | 'critical';
  lastCalculated: Date;
}

interface ModelPerformance {
  modelId: string;
  modelName: string;
  modelType: string;
  metrics: {
    mape: number; // Mean Absolute Percentage Error
    rmse: number; // Root Mean Square Error
    mae: number;  // Mean Absolute Error
    mase: number; // Mean Absolute Scaled Error
    smape: number; // Symmetric Mean Absolute Percentage Error
    r_squared: number;
  };
  accuracy: number;
  bias: number;
  lastEvaluation: Date;
  dataPoints: number;
}

interface AccuracyTrend {
  date: string;
  mape: number;
  accuracy: number;
  dataPoints: number;
  modelId: string;
}

interface BenchmarkData {
  metric: string;
  currentValue: number;
  industryAverage: number;
  bestPractice: number;
  percentile: number;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const AccuracyMetricsDashboard: React.FC = () => {
  const [accuracyMetrics, setAccuracyMetrics] = useState<AccuracyMetric[]>([]);
  const [modelPerformance, setModelPerformance] = useState<ModelPerformance[]>([]);
  const [accuracyTrends, setAccuracyTrends] = useState<AccuracyTrend[]>([]);
  const [benchmarkData, setBenchmarkData] = useState<BenchmarkData[]>([]);
  const [selectedModel, setSelectedModel] = useState<string>('all');
  const [selectedTimeframe, setSelectedTimeframe] = useState('30days');
  const [isLoading, setIsLoading] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(new Date());

  const loadAccuracyData = async () => {
    setIsLoading(true);

    try {
      console.log('[ACCURACY DASHBOARD] Loading accuracy metrics and performance data...');

      // Load accuracy metrics
      const metricsResponse = await fetch(`${API_BASE_URL}/forecasting/accuracy-metrics?timeframe=${selectedTimeframe}&model=${selectedModel}`);
      if (!metricsResponse.ok) {
        throw new Error(`Metrics API failed: ${metricsResponse.status}`);
      }

      const metricsData = await metricsResponse.json();
      const realMetrics = (metricsData.metrics || []).map((metric: any) => ({
        id: metric.id || `metric_${Date.now()}`,
        name: metric.name || metric.metric_name,
        value: metric.value || metric.current_value || 0,
        target: metric.target || metric.target_value || 0,
        unit: metric.unit || metric.measurement_unit || '%',
        description: metric.description || metric.summary || '',
        trend: metric.trend || metric.trend_direction || 'stable',
        status: metric.status || metric.health_status || 'good',
        lastCalculated: new Date(metric.last_calculated || metric.lastCalculated || Date.now())
      }));

      setAccuracyMetrics(realMetrics);

      // Load model performance
      const modelsResponse = await fetch(`${API_BASE_URL}/forecasting/model-performance?timeframe=${selectedTimeframe}`);
      if (modelsResponse.ok) {
        const modelsData = await modelsResponse.json();
        setModelPerformance(modelsData.models || []);
      }

      // Load accuracy trends
      const trendsResponse = await fetch(`${API_BASE_URL}/forecasting/accuracy-trends?timeframe=${selectedTimeframe}&model=${selectedModel}`);
      if (trendsResponse.ok) {
        const trendsData = await trendsResponse.json();
        setAccuracyTrends(trendsData.trends || []);
      }

      // Load benchmark data
      const benchmarkResponse = await fetch(`${API_BASE_URL}/forecasting/benchmarks`);
      if (benchmarkResponse.ok) {
        const benchmarkData = await benchmarkResponse.json();
        setBenchmarkData(benchmarkData.benchmarks || []);
      }

      setLastUpdate(new Date());
      console.log(`[ACCURACY DASHBOARD] Loaded ${realMetrics.length} accuracy metrics`);

    } catch (error) {
      console.error('[ACCURACY DASHBOARD] Error loading data:', error);

      // Fallback data for demo
      const fallbackMetrics: AccuracyMetric[] = [
        {
          id: 'mape-overall',
          name: 'Общая MAPE',
          value: 8.2,
          target: 10.0,
          unit: '%',
          description: 'Средняя абсолютная процентная ошибка по всем моделям',
          trend: 'down',
          status: 'good',
          lastCalculated: new Date(Date.now() - 3600000)
        },
        {
          id: 'forecast-accuracy',
          name: 'Точность прогноза',
          value: 91.8,
          target: 90.0,
          unit: '%',
          description: 'Общая точность прогнозирования за последний период',
          trend: 'up',
          status: 'good',
          lastCalculated: new Date(Date.now() - 1800000)
        },
        {
          id: 'bias',
          name: 'Систематическая ошибка',
          value: -2.1,
          target: 0.0,
          unit: '%',
          description: 'Смещение прогнозов относительно фактических значений',
          trend: 'stable',
          status: 'warning',
          lastCalculated: new Date(Date.now() - 900000)
        },
        {
          id: 'coverage-probability',
          name: 'Покрытие интервалов',
          value: 94.5,
          target: 95.0,
          unit: '%',
          description: 'Процент фактических значений в доверительных интервалах',
          trend: 'down',
          status: 'warning',
          lastCalculated: new Date(Date.now() - 600000)
        },
        {
          id: 'model-stability',
          name: 'Стабильность модели',
          value: 87.3,
          target: 85.0,
          unit: '%',
          description: 'Консистентность производительности модели во времени',
          trend: 'up',
          status: 'good',
          lastCalculated: new Date(Date.now() - 300000)
        },
        {
          id: 'data-quality-score',
          name: 'Качество данных',
          value: 96.7,
          target: 95.0,
          unit: '%',
          description: 'Оценка полноты и качества входящих данных',
          trend: 'stable',
          status: 'good',
          lastCalculated: new Date(Date.now() - 1200000)
        }
      ];

      const fallbackModels: ModelPerformance[] = [
        {
          modelId: 'arima-model-1',
          modelName: 'ARIMA (2,1,2)',
          modelType: 'ARIMA',
          metrics: {
            mape: 7.8,
            rmse: 12.4,
            mae: 9.2,
            mase: 0.85,
            smape: 7.5,
            r_squared: 0.89
          },
          accuracy: 92.2,
          bias: -1.5,
          lastEvaluation: new Date(Date.now() - 3600000),
          dataPoints: 730
        },
        {
          modelId: 'neural-model-1',
          modelName: 'LSTM Neural Network',
          modelType: 'Neural Network',
          metrics: {
            mape: 6.9,
            rmse: 11.1,
            mae: 8.5,
            mase: 0.78,
            smape: 6.7,
            r_squared: 0.92
          },
          accuracy: 93.1,
          bias: 0.8,
          lastEvaluation: new Date(Date.now() - 1800000),
          dataPoints: 730
        },
        {
          modelId: 'ensemble-model-1',
          modelName: 'Ensemble Model',
          modelType: 'Ensemble',
          metrics: {
            mape: 6.2,
            rmse: 10.3,
            mae: 7.8,
            mase: 0.72,
            smape: 6.1,
            r_squared: 0.94
          },
          accuracy: 93.8,
          bias: 0.3,
          lastEvaluation: new Date(Date.now() - 900000),
          dataPoints: 730
        },
        {
          modelId: 'exponential-model-1',
          modelName: 'Triple Exponential',
          modelType: 'Exponential Smoothing',
          metrics: {
            mape: 9.1,
            rmse: 14.7,
            mae: 11.2,
            mase: 1.02,
            smape: 8.9,
            r_squared: 0.82
          },
          accuracy: 90.9,
          bias: -2.8,
          lastEvaluation: new Date(Date.now() - 7200000),
          dataPoints: 730
        }
      ];

      const fallbackTrends: AccuracyTrend[] = Array.from({ length: 30 }, (_, i) => ({
        date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        mape: 6 + Math.random() * 4 + Math.sin(i / 7) * 2,
        accuracy: 88 + Math.random() * 8 + Math.cos(i / 7) * 3,
        dataPoints: 45 + Math.floor(Math.random() * 20),
        modelId: 'ensemble-model-1'
      }));

      const fallbackBenchmarks: BenchmarkData[] = [
        {
          metric: 'MAPE',
          currentValue: 8.2,
          industryAverage: 12.5,
          bestPractice: 6.0,
          percentile: 75
        },
        {
          metric: 'Точность прогноза',
          currentValue: 91.8,
          industryAverage: 87.5,
          bestPractice: 95.0,
          percentile: 80
        },
        {
          metric: 'Покрытие интервалов',
          currentValue: 94.5,
          industryAverage: 92.0,
          bestPractice: 96.0,
          percentile: 70
        },
        {
          metric: 'Стабильность модели',
          currentValue: 87.3,
          industryAverage: 82.0,
          bestPractice: 90.0,
          percentile: 65
        }
      ];

      setAccuracyMetrics(fallbackMetrics);
      setModelPerformance(fallbackModels);
      setAccuracyTrends(fallbackTrends);
      setBenchmarkData(fallbackBenchmarks);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadAccuracyData();
  }, [selectedModel, selectedTimeframe]);

  const refreshMetrics = async () => {
    await loadAccuracyData();
  };

  const exportReport = () => {
    const reportData = {
      metrics: accuracyMetrics,
      modelPerformance,
      trends: accuracyTrends,
      benchmarks: benchmarkData,
      parameters: {
        model: selectedModel,
        timeframe: selectedTimeframe
      },
      generatedAt: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(reportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `accuracy-report-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getStatusIcon = (status: AccuracyMetric['status']) => {
    switch (status) {
      case 'good':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'warning':
        return <AlertCircle className="h-4 w-4 text-yellow-500" />;
      case 'critical':
        return <AlertCircle className="h-4 w-4 text-red-500" />;
      default:
        return <Target className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusColor = (status: AccuracyMetric['status']) => {
    switch (status) {
      case 'good':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'warning':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'critical':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getTrendIcon = (trend: AccuracyMetric['trend']) => {
    switch (trend) {
      case 'up':
        return <TrendingUp className="h-3 w-3 text-green-500" />;
      case 'down':
        return <TrendingUp className="h-3 w-3 text-red-500 rotate-180" />;
      default:
        return <div className="h-3 w-3 bg-gray-400 rounded-full" />;
    }
  };

  const formatMetricValue = (value: number, unit: string) => {
    return `${value.toFixed(unit === '%' ? 1 : 2)}${unit}`;
  };

  const getPercentileColor = (percentile: number) => {
    if (percentile >= 80) return 'text-green-600';
    if (percentile >= 60) return 'text-yellow-600';
    return 'text-red-600';
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <Target className="h-6 w-6 mr-2 text-blue-600" />
              Дашборд Метрик Точности
            </h2>
            <p className="mt-2 text-gray-600">
              Мониторинг и анализ точности моделей прогнозирования
            </p>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Calendar className="h-4 w-4 text-gray-500" />
              <span className="text-sm text-gray-600">
                Обновлено: {lastUpdate.toLocaleTimeString('ru-RU')}
              </span>
            </div>
            <button
              onClick={exportReport}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              <Download className="h-4 w-4 mr-2" />
              Экспорт отчета
            </button>
            <button
              onClick={refreshMetrics}
              disabled={isLoading}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
              {isLoading ? 'Обновление...' : 'Обновить'}
            </button>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div className="flex items-center gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Модель
            </label>
            <select
              value={selectedModel}
              onChange={(e) => setSelectedModel(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">Все модели</option>
              {modelPerformance.map(model => (
                <option key={model.modelId} value={model.modelId}>
                  {model.modelName}
                </option>
              ))}
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Период
            </label>
            <select
              value={selectedTimeframe}
              onChange={(e) => setSelectedTimeframe(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="7days">7 дней</option>
              <option value="30days">30 дней</option>
              <option value="90days">90 дней</option>
              <option value="1year">1 год</option>
            </select>
          </div>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="mb-8 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {accuracyMetrics.map((metric) => (
          <div key={metric.id} className={`bg-white rounded-lg shadow-sm border p-6 ${getStatusColor(metric.status)}`}>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                {getStatusIcon(metric.status)}
                <h3 className="text-lg font-semibold text-gray-900">{metric.name}</h3>
              </div>
              {getTrendIcon(metric.trend)}
            </div>
            
            <div className="mb-4">
              <div className="flex items-baseline gap-2">
                <span className="text-3xl font-bold text-gray-900">
                  {formatMetricValue(metric.value, metric.unit)}
                </span>
                <span className="text-sm text-gray-600">
                  / {formatMetricValue(metric.target, metric.unit)} цель
                </span>
              </div>
              
              <div className="mt-2">
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      metric.value >= metric.target ? 'bg-green-500' : 
                      metric.value >= metric.target * 0.8 ? 'bg-yellow-500' : 'bg-red-500'
                    }`}
                    style={{ 
                      width: `${Math.min(100, (metric.value / metric.target) * 100)}%` 
                    }}
                  ></div>
                </div>
              </div>
            </div>
            
            <p className="text-sm text-gray-600 mb-2">{metric.description}</p>
            
            <div className="text-xs text-gray-500">
              Обновлено: {metric.lastCalculated.toLocaleTimeString('ru-RU')}
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Model Performance Comparison */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Производительность моделей</h3>
          </div>
          
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Модель
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    MAPE
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Точность
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    R²
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Смещение
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {modelPerformance.map((model) => (
                  <tr key={model.modelId} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">{model.modelName}</div>
                        <div className="text-sm text-gray-500">{model.modelType}</div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`text-sm font-medium ${
                        model.metrics.mape < 8 ? 'text-green-600' :
                        model.metrics.mape < 12 ? 'text-yellow-600' : 'text-red-600'
                      }`}>
                        {model.metrics.mape.toFixed(1)}%
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`text-sm font-medium ${
                        model.accuracy > 92 ? 'text-green-600' :
                        model.accuracy > 88 ? 'text-yellow-600' : 'text-red-600'
                      }`}>
                        {model.accuracy.toFixed(1)}%
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {model.metrics.r_squared.toFixed(3)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`text-sm ${
                        Math.abs(model.bias) < 2 ? 'text-green-600' :
                        Math.abs(model.bias) < 5 ? 'text-yellow-600' : 'text-red-600'
                      }`}>
                        {model.bias > 0 ? '+' : ''}{model.bias.toFixed(1)}%
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Industry Benchmarks */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Сравнение с отраслью</h3>
          </div>
          
          <div className="p-6 space-y-6">
            {benchmarkData.map((benchmark, index) => (
              <div key={index}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-gray-900">{benchmark.metric}</span>
                  <span className={`text-sm font-bold ${getPercentileColor(benchmark.percentile)}`}>
                    {benchmark.percentile}-й процентиль
                  </span>
                </div>
                
                <div className="space-y-1">
                  <div className="flex justify-between text-xs text-gray-600">
                    <span>Ваш результат</span>
                    <span className="font-medium text-blue-600">{benchmark.currentValue.toFixed(1)}</span>
                  </div>
                  <div className="flex justify-between text-xs text-gray-600">
                    <span>Средний по отрасли</span>
                    <span>{benchmark.industryAverage.toFixed(1)}</span>
                  </div>
                  <div className="flex justify-between text-xs text-gray-600">
                    <span>Лучшая практика</span>
                    <span className="font-medium text-green-600">{benchmark.bestPractice.toFixed(1)}</span>
                  </div>
                </div>
                
                <div className="mt-2 relative">
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-blue-500 h-2 rounded-full"
                      style={{
                        width: `${(benchmark.currentValue / benchmark.bestPractice) * 100}%`
                      }}
                    ></div>
                  </div>
                  <div className="flex justify-between mt-1">
                    <span className="text-xs text-gray-500">0</span>
                    <span className="text-xs text-gray-500">{benchmark.bestPractice.toFixed(1)}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Accuracy Trends Chart Placeholder */}
      <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Тренды точности</h3>
        <div className="h-64 flex items-center justify-center bg-gray-50 rounded-lg">
          <div className="text-center text-gray-500">
            <BarChart3 className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>Интерактивный график трендов точности</p>
            <p className="text-sm">MAPE, точность прогноза и качество данных во времени</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AccuracyMetricsDashboard;