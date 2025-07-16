import React, { useState, useEffect } from 'react';
import { BarChart3, Activity, AlertCircle, TrendingUp, Download, RefreshCw, Settings, Filter } from 'lucide-react';

interface VariabilityMetric {
  id: string;
  name: string;
  value: number;
  threshold: number;
  unit: string;
  status: 'normal' | 'elevated' | 'critical';
  trend: 'increasing' | 'decreasing' | 'stable';
  description: string;
  lastCalculated: Date;
}

interface DemandPeriod {
  date: string;
  actual: number;
  forecast: number;
  variance: number;
  volatilityIndex: number;
  outlierScore: number;
  seasonalAdjusted: number;
}

interface VariabilityPattern {
  id: string;
  name: string;
  type: 'cyclical' | 'random' | 'structural' | 'seasonal';
  strength: number;
  frequency: string;
  impact: 'high' | 'medium' | 'low';
  description: string;
  detectedAt: Date;
  confidence: number;
}

interface VolatilityForecast {
  date: string;
  expectedVolatility: number;
  lowerBound: number;
  upperBound: number;
  confidenceLevel: number;
  riskLevel: 'low' | 'medium' | 'high' | 'extreme';
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const DemandVariabilityAnalyzer: React.FC = () => {
  const [variabilityMetrics, setVariabilityMetrics] = useState<VariabilityMetric[]>([]);
  const [demandPeriods, setDemandPeriods] = useState<DemandPeriod[]>([]);
  const [variabilityPatterns, setVariabilityPatterns] = useState<VariabilityPattern[]>([]);
  const [volatilityForecasts, setVolatilityForecasts] = useState<VolatilityForecast[]>([]);
  const [selectedDataSource, setSelectedDataSource] = useState('calls');
  const [analysisWindow, setAnalysisWindow] = useState('30days');
  const [volatilityMethod, setVolatilityMethod] = useState('garch');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [showAdvancedSettings, setShowAdvancedSettings] = useState(false);
  const [lastAnalysis, setLastAnalysis] = useState(new Date());

  const loadVariabilityData = async () => {
    setIsAnalyzing(true);

    try {
      console.log('[VARIABILITY ANALYZER] Loading demand variability analysis...');

      // Load variability metrics
      const metricsResponse = await fetch(`${API_BASE_URL}/analytics/variability-metrics?source=${selectedDataSource}&window=${analysisWindow}`);
      if (!metricsResponse.ok) {
        throw new Error(`Metrics API failed: ${metricsResponse.status}`);
      }

      const metricsData = await metricsResponse.json();
      const realMetrics = (metricsData.metrics || []).map((metric: any) => ({
        id: metric.id || `metric_${Date.now()}`,
        name: metric.name || metric.metric_name,
        value: metric.value || metric.current_value || 0,
        threshold: metric.threshold || metric.threshold_value || 0,
        unit: metric.unit || metric.measurement_unit || '',
        status: metric.status || metric.risk_level || 'normal',
        trend: metric.trend || metric.trend_direction || 'stable',
        description: metric.description || metric.summary || '',
        lastCalculated: new Date(metric.last_calculated || metric.lastCalculated || Date.now())
      }));

      setVariabilityMetrics(realMetrics);

      // Load demand periods
      const periodsResponse = await fetch(`${API_BASE_URL}/analytics/demand-periods?source=${selectedDataSource}&window=${analysisWindow}`);
      if (periodsResponse.ok) {
        const periodsData = await periodsResponse.json();
        setDemandPeriods(periodsData.periods || []);
      }

      // Load variability patterns
      const patternsResponse = await fetch(`${API_BASE_URL}/analytics/variability-patterns?source=${selectedDataSource}&window=${analysisWindow}`);
      if (patternsResponse.ok) {
        const patternsData = await patternsResponse.json();
        setVariabilityPatterns(patternsData.patterns || []);
      }

      // Load volatility forecasts
      const forecastsResponse = await fetch(`${API_BASE_URL}/analytics/volatility-forecasts?method=${volatilityMethod}&horizon=14`);
      if (forecastsResponse.ok) {
        const forecastsData = await forecastsResponse.json();
        setVolatilityForecasts(forecastsData.forecasts || []);
      }

      setLastAnalysis(new Date());
      console.log(`[VARIABILITY ANALYZER] Loaded ${realMetrics.length} variability metrics`);

    } catch (error) {
      console.error('[VARIABILITY ANALYZER] Error loading data:', error);

      // Fallback data for demo
      const fallbackMetrics: VariabilityMetric[] = [
        {
          id: 'coefficient-variation',
          name: 'Коэффициент вариации',
          value: 0.23,
          threshold: 0.30,
          unit: '',
          status: 'normal',
          trend: 'increasing',
          description: 'Мера относительной изменчивости спроса',
          lastCalculated: new Date(Date.now() - 3600000)
        },
        {
          id: 'volatility-index',
          name: 'Индекс волатильности',
          value: 0.18,
          threshold: 0.25,
          unit: '',
          status: 'normal',
          trend: 'stable',
          description: 'Среднесрочная волатильность спроса',
          lastCalculated: new Date(Date.now() - 1800000)
        },
        {
          id: 'forecast-error-variance',
          name: 'Дисперсия ошибок прогноза',
          value: 12.7,
          threshold: 15.0,
          unit: '%',
          status: 'normal',
          trend: 'decreasing',
          description: 'Вариативность точности прогнозирования',
          lastCalculated: new Date(Date.now() - 900000)
        },
        {
          id: 'outlier-frequency',
          name: 'Частота выбросов',
          value: 0.08,
          threshold: 0.10,
          unit: '',
          status: 'normal',
          trend: 'stable',
          description: 'Доля аномальных значений в данных',
          lastCalculated: new Date(Date.now() - 600000)
        },
        {
          id: 'seasonal-variance',
          name: 'Сезонная дисперсия',
          value: 0.31,
          threshold: 0.40,
          unit: '',
          status: 'normal',
          trend: 'increasing',
          description: 'Изменчивость сезонных паттернов',
          lastCalculated: new Date(Date.now() - 300000)
        },
        {
          id: 'demand-instability',
          name: 'Нестабильность спроса',
          value: 0.42,
          threshold: 0.50,
          unit: '',
          status: 'elevated',
          trend: 'increasing',
          description: 'Общая непредсказуемость спроса',
          lastCalculated: new Date(Date.now() - 1200000)
        }
      ];

      const fallbackPeriods: DemandPeriod[] = Array.from({ length: 30 }, (_, i) => {
        const baseValue = 150 + Math.sin(i / 7 * Math.PI) * 20;
        const noise = (Math.random() - 0.5) * 40;
        const actual = Math.max(0, baseValue + noise);
        const forecast = baseValue + (Math.random() - 0.5) * 20;
        
        return {
          date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          actual,
          forecast,
          variance: Math.pow(actual - forecast, 2),
          volatilityIndex: Math.abs(noise) / baseValue,
          outlierScore: Math.abs(noise) > 30 ? 1 : 0,
          seasonalAdjusted: actual - Math.sin(i / 7 * Math.PI) * 20
        };
      });

      const fallbackPatterns: VariabilityPattern[] = [
        {
          id: 'weekly-volatility',
          name: 'Недельная волатильность',
          type: 'cyclical',
          strength: 0.75,
          frequency: 'weekly',
          impact: 'high',
          description: 'Регулярные колебания спроса в течение недели с пиками в понедельник и пятницу',
          detectedAt: new Date(Date.now() - 86400000),
          confidence: 0.92
        },
        {
          id: 'random-spikes',
          name: 'Случайные всплески',
          type: 'random',
          strength: 0.45,
          frequency: 'irregular',
          impact: 'medium',
          description: 'Непредсказуемые всплески спроса без четкой закономерности',
          detectedAt: new Date(Date.now() - 172800000),
          confidence: 0.67
        },
        {
          id: 'structural-shift',
          name: 'Структурный сдвиг',
          type: 'structural',
          strength: 0.83,
          frequency: 'one-time',
          impact: 'high',
          description: 'Значительное изменение базового уровня спроса',
          detectedAt: new Date(Date.now() - 604800000),
          confidence: 0.89
        },
        {
          id: 'holiday-variance',
          name: 'Праздничная вариативность',
          type: 'seasonal',
          strength: 0.92,
          frequency: 'annual',
          impact: 'high',
          description: 'Значительные отклонения в периоды праздников и отпусков',
          detectedAt: new Date(Date.now() - 1209600000),
          confidence: 0.95
        }
      ];

      const fallbackForecasts: VolatilityForecast[] = Array.from({ length: 14 }, (_, i) => {
        const baseVolatility = 0.15 + Math.sin(i / 7 * Math.PI) * 0.05;
        const margin = 0.03;
        
        return {
          date: new Date(Date.now() + i * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          expectedVolatility: baseVolatility,
          lowerBound: baseVolatility - margin,
          upperBound: baseVolatility + margin,
          confidenceLevel: 90,
          riskLevel: baseVolatility > 0.20 ? 'high' : baseVolatility > 0.15 ? 'medium' : 'low'
        };
      });

      setVariabilityMetrics(fallbackMetrics);
      setDemandPeriods(fallbackPeriods);
      setVariabilityPatterns(fallbackPatterns);
      setVolatilityForecasts(fallbackForecasts);
    } finally {
      setIsAnalyzing(false);
    }
  };

  useEffect(() => {
    loadVariabilityData();
  }, [selectedDataSource, analysisWindow, volatilityMethod]);

  const runVariabilityAnalysis = async () => {
    setIsAnalyzing(true);
    
    try {
      const response = await fetch(`${API_BASE_URL}/analytics/variability-analysis`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          data_source: selectedDataSource,
          window: analysisWindow,
          method: volatilityMethod
        })
      });

      if (response.ok) {
        const result = await response.json();
        setVariabilityMetrics(result.metrics || []);
        setDemandPeriods(result.periods || []);
        setVariabilityPatterns(result.patterns || []);
        setVolatilityForecasts(result.forecasts || []);
      }
    } catch (error) {
      console.error('Failed to run variability analysis:', error);
    } finally {
      setTimeout(() => setIsAnalyzing(false), 2000);
    }
  };

  const exportAnalysis = () => {
    const exportData = {
      metrics: variabilityMetrics,
      periods: demandPeriods,
      patterns: variabilityPatterns,
      forecasts: volatilityForecasts,
      parameters: {
        dataSource: selectedDataSource,
        window: analysisWindow,
        method: volatilityMethod
      },
      timestamp: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `variability-analysis-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getStatusColor = (status: VariabilityMetric['status']) => {
    switch (status) {
      case 'normal':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'elevated':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'critical':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getPatternTypeColor = (type: VariabilityPattern['type']) => {
    switch (type) {
      case 'cyclical':
        return 'bg-blue-100 text-blue-800';
      case 'random':
        return 'bg-orange-100 text-orange-800';
      case 'structural':
        return 'bg-purple-100 text-purple-800';
      case 'seasonal':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getRiskLevelColor = (riskLevel: VolatilityForecast['riskLevel']) => {
    switch (riskLevel) {
      case 'low':
        return 'text-green-600';
      case 'medium':
        return 'text-yellow-600';
      case 'high':
        return 'text-red-600';
      case 'extreme':
        return 'text-red-800';
      default:
        return 'text-gray-600';
    }
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <Activity className="h-6 w-6 mr-2 text-blue-600" />
              Анализатор Вариативности Спроса
            </h2>
            <p className="mt-2 text-gray-600">
              Анализ волатильности и непредсказуемости спроса для улучшения планирования
            </p>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={() => setShowAdvancedSettings(!showAdvancedSettings)}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              <Settings className="h-4 w-4 mr-2" />
              Настройки
            </button>
            <button
              onClick={exportAnalysis}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              <Download className="h-4 w-4 mr-2" />
              Экспорт
            </button>
            <button
              onClick={runVariabilityAnalysis}
              disabled={isAnalyzing}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${isAnalyzing ? 'animate-spin' : ''}`} />
              {isAnalyzing ? 'Анализируем...' : 'Запустить анализ'}
            </button>
          </div>
        </div>
      </div>

      {/* Advanced Settings */}
      {showAdvancedSettings && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Параметры анализа</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Источник данных
              </label>
              <select
                value={selectedDataSource}
                onChange={(e) => setSelectedDataSource(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="calls">Звонки</option>
                <option value="chats">Чаты</option>
                <option value="emails">Email</option>
                <option value="tickets">Заявки</option>
                <option value="all">Все каналы</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Окно анализа
              </label>
              <select
                value={analysisWindow}
                onChange={(e) => setAnalysisWindow(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="7days">7 дней</option>
                <option value="30days">30 дней</option>
                <option value="90days">90 дней</option>
                <option value="1year">1 год</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Метод анализа волатильности
              </label>
              <select
                value={volatilityMethod}
                onChange={(e) => setVolatilityMethod(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="garch">GARCH</option>
                <option value="ewma">EWMA</option>
                <option value="historical">Историческая</option>
                <option value="parkinson">Паркинсон</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {/* Variability Metrics */}
      <div className="mb-8 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {variabilityMetrics.map((metric) => (
          <div key={metric.id} className={`bg-white rounded-lg shadow-sm border p-6 ${getStatusColor(metric.status)}`}>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Activity className="h-5 w-5 text-blue-600" />
                <h3 className="text-lg font-semibold text-gray-900">{metric.name}</h3>
              </div>
              <span className="text-xs px-2 py-1 bg-gray-100 rounded-full">
                {metric.trend === 'increasing' ? '↗' : metric.trend === 'decreasing' ? '↘' : '→'}
              </span>
            </div>
            
            <div className="mb-4">
              <div className="flex items-baseline gap-2">
                <span className="text-3xl font-bold text-gray-900">
                  {metric.value.toFixed(metric.unit === '%' ? 1 : 3)}{metric.unit}
                </span>
                <span className="text-sm text-gray-600">
                  / {metric.threshold.toFixed(metric.unit === '%' ? 1 : 3)}{metric.unit} порог
                </span>
              </div>
              
              <div className="mt-2">
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      metric.value >= metric.threshold ? 'bg-red-500' : 
                      metric.value >= metric.threshold * 0.8 ? 'bg-yellow-500' : 'bg-green-500'
                    }`}
                    style={{ 
                      width: `${Math.min(100, (metric.value / metric.threshold) * 100)}%` 
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
        {/* Variability Patterns */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Паттерны вариативности</h3>
          </div>
          
          <div className="p-6 space-y-4">
            {variabilityPatterns.map((pattern) => (
              <div key={pattern.id} className="p-4 border border-gray-200 rounded-lg">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-medium text-gray-900">{pattern.name}</span>
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getPatternTypeColor(pattern.type)}`}>
                      {pattern.type}
                    </span>
                  </div>
                  <span className={`text-sm font-medium ${
                    pattern.impact === 'high' ? 'text-red-600' :
                    pattern.impact === 'medium' ? 'text-yellow-600' : 'text-green-600'
                  }`}>
                    {pattern.impact === 'high' ? 'Высокий' :
                     pattern.impact === 'medium' ? 'Средний' : 'Низкий'} риск
                  </span>
                </div>
                
                <p className="text-sm text-gray-600 mb-3">{pattern.description}</p>
                
                <div className="grid grid-cols-3 gap-4 text-sm">
                  <div className="text-center">
                    <div className="font-medium text-gray-900">{(pattern.strength * 100).toFixed(0)}%</div>
                    <div className="text-gray-500">Сила</div>
                  </div>
                  <div className="text-center">
                    <div className="font-medium text-gray-900">{pattern.frequency}</div>
                    <div className="text-gray-500">Частота</div>
                  </div>
                  <div className="text-center">
                    <div className="font-medium text-gray-900">{(pattern.confidence * 100).toFixed(0)}%</div>
                    <div className="text-gray-500">Уверенность</div>
                  </div>
                </div>
                
                <div className="mt-3 text-xs text-gray-500">
                  Обнаружен: {pattern.detectedAt.toLocaleDateString('ru-RU')}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Volatility Forecast */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Прогноз волатильности</h3>
          </div>
          
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Дата
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Волатильность
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Интервал
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Риск
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {volatilityForecasts.slice(0, 10).map((forecast, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {new Date(forecast.date).toLocaleDateString('ru-RU')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm font-medium text-blue-600">
                        {(forecast.expectedVolatility * 100).toFixed(1)}%
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                      {(forecast.lowerBound * 100).toFixed(1)}% - {(forecast.upperBound * 100).toFixed(1)}%
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`text-sm font-medium ${getRiskLevelColor(forecast.riskLevel)}`}>
                        {forecast.riskLevel === 'low' ? 'Низкий' :
                         forecast.riskLevel === 'medium' ? 'Средний' :
                         forecast.riskLevel === 'high' ? 'Высокий' : 'Экстремальный'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Historical Analysis Chart Placeholder */}
      <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Историческая волатильность</h3>
        <div className="h-64 flex items-center justify-center bg-gray-50 rounded-lg">
          <div className="text-center text-gray-500">
            <BarChart3 className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>Интерактивный график волатильности спроса</p>
            <p className="text-sm">Скользящая волатильность, GARCH-модель и прогнозные интервалы</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DemandVariabilityAnalyzer;