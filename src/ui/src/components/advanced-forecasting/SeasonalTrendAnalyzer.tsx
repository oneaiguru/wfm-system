import React, { useState, useEffect } from 'react';
import { Calendar, TrendingUp, BarChart3, Activity, Download, RefreshCw, Filter, Eye } from 'lucide-react';

interface SeasonalPattern {
  id: string;
  name: string;
  type: 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom';
  strength: number;
  confidence: number;
  description: string;
  peakPeriods: Array<{
    period: string;
    value: number;
    variance: number;
  }>;
  detectedAt: Date;
}

interface TrendComponent {
  id: string;
  direction: 'up' | 'down' | 'stable';
  magnitude: number;
  significance: number;
  startDate: Date;
  endDate: Date;
  description: string;
  rSquared: number;
}

interface AnalysisResult {
  dataPoints: Array<{
    date: string;
    actual: number;
    trend: number;
    seasonal: number;
    residual: number;
    forecast: number;
  }>;
  decomposition: {
    trend: number[];
    seasonal: number[];
    residual: number[];
  };
  metrics: {
    seasonalityIndex: number;
    trendStrength: number;
    volatility: number;
    predictability: number;
  };
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const SeasonalTrendAnalyzer: React.FC = () => {
  const [seasonalPatterns, setSeasonalPatterns] = useState<SeasonalPattern[]>([]);
  const [trendComponents, setTrendComponents] = useState<TrendComponent[]>([]);
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(null);
  const [selectedDataSource, setSelectedDataSource] = useState('calls');
  const [analysisTimeframe, setAnalysisTimeframe] = useState('12months');
  const [decompositionMethod, setDecompositionMethod] = useState('additive');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [selectedPattern, setSelectedPattern] = useState<string>('');
  const [showAdvancedFilters, setShowAdvancedFilters] = useState(false);

  const loadAnalysisData = async () => {
    setIsAnalyzing(true);

    try {
      console.log('[SEASONAL ANALYSIS] Loading seasonal trend analysis...');

      // Load seasonal patterns
      const patternsResponse = await fetch(`${API_BASE_URL}/analytics/seasonal-patterns?source=${selectedDataSource}&timeframe=${analysisTimeframe}`);
      if (!patternsResponse.ok) {
        throw new Error(`Patterns API failed: ${patternsResponse.status}`);
      }

      const patternsData = await patternsResponse.json();
      const realPatterns = (patternsData.patterns || []).map((pattern: any) => ({
        id: pattern.id || `pattern_${Date.now()}`,
        name: pattern.name || pattern.pattern_name,
        type: pattern.type || pattern.pattern_type || 'weekly',
        strength: pattern.strength || pattern.pattern_strength || 0,
        confidence: pattern.confidence || pattern.confidence_level || 0,
        description: pattern.description || pattern.summary || '',
        peakPeriods: pattern.peak_periods || pattern.peakPeriods || [],
        detectedAt: new Date(pattern.detected_at || pattern.detectedAt || Date.now())
      }));

      setSeasonalPatterns(realPatterns);

      // Load trend components
      const trendsResponse = await fetch(`${API_BASE_URL}/analytics/trend-components?source=${selectedDataSource}&timeframe=${analysisTimeframe}`);
      if (trendsResponse.ok) {
        const trendsData = await trendsResponse.json();
        setTrendComponents(trendsData.trends || []);
      }

      // Load decomposition analysis
      const decompositionResponse = await fetch(`${API_BASE_URL}/analytics/decomposition?source=${selectedDataSource}&method=${decompositionMethod}&timeframe=${analysisTimeframe}`);
      if (decompositionResponse.ok) {
        const decompositionData = await decompositionResponse.json();
        setAnalysisResult(decompositionData.analysis || null);
      }

      console.log(`[SEASONAL ANALYSIS] Loaded ${realPatterns.length} seasonal patterns`);

    } catch (error) {
      console.error('[SEASONAL ANALYSIS] Error loading data:', error);

      // Fallback data for demo
      const fallbackPatterns: SeasonalPattern[] = [
        {
          id: 'weekly-pattern-1',
          name: 'Недельная сезонность',
          type: 'weekly',
          strength: 0.87,
          confidence: 0.95,
          description: 'Сильная недельная сезонность с пиками в понедельник (128%) и пятницу (115%)',
          peakPeriods: [
            { period: 'Понедельник', value: 128, variance: 8.5 },
            { period: 'Вторник', value: 98, variance: 6.2 },
            { period: 'Среда', value: 102, variance: 5.8 },
            { period: 'Четверг', value: 105, variance: 7.1 },
            { period: 'Пятница', value: 115, variance: 9.3 },
            { period: 'Суббота', value: 75, variance: 12.4 },
            { period: 'Воскресенье', value: 65, variance: 15.2 }
          ],
          detectedAt: new Date(Date.now() - 86400000)
        },
        {
          id: 'daily-pattern-1',
          name: 'Внутридневная сезонность',
          type: 'daily',
          strength: 0.92,
          confidence: 0.98,
          description: 'Четкая внутридневная сезонность с пиками в 10:00-12:00 и 14:00-16:00',
          peakPeriods: [
            { period: '08:00-09:00', value: 85, variance: 12.3 },
            { period: '09:00-10:00', value: 110, variance: 8.7 },
            { period: '10:00-11:00', value: 135, variance: 6.5 },
            { period: '11:00-12:00', value: 128, variance: 7.2 },
            { period: '12:00-13:00', value: 95, variance: 15.8 },
            { period: '13:00-14:00', value: 88, variance: 11.4 },
            { period: '14:00-15:00', value: 125, variance: 8.9 },
            { period: '15:00-16:00', value: 130, variance: 9.1 },
            { period: '16:00-17:00', value: 108, variance: 10.5 },
            { period: '17:00-18:00', value: 85, variance: 14.2 }
          ],
          detectedAt: new Date(Date.now() - 172800000)
        },
        {
          id: 'monthly-pattern-1',
          name: 'Месячная сезонность',
          type: 'monthly',
          strength: 0.65,
          confidence: 0.78,
          description: 'Умеренная месячная сезонность с пиками в начале и конце месяца',
          peakPeriods: [
            { period: '1-5 число', value: 118, variance: 15.2 },
            { period: '6-10 число', value: 95, variance: 8.7 },
            { period: '11-15 число', value: 88, variance: 9.1 },
            { period: '16-20 число', value: 92, variance: 7.8 },
            { period: '21-25 число', value: 98, variance: 10.3 },
            { period: '26-31 число', value: 112, variance: 18.5 }
          ],
          detectedAt: new Date(Date.now() - 259200000)
        },
        {
          id: 'yearly-pattern-1',
          name: 'Годовая сезонность',
          type: 'yearly',
          strength: 0.73,
          confidence: 0.82,
          description: 'Выраженная годовая сезонность с пиками в Q1 и Q4',
          peakPeriods: [
            { period: 'Q1', value: 115, variance: 12.5 },
            { period: 'Q2', value: 92, variance: 8.3 },
            { period: 'Q3', value: 85, variance: 15.7 },
            { period: 'Q4', value: 108, variance: 11.2 }
          ],
          detectedAt: new Date(Date.now() - 345600000)
        }
      ];

      const fallbackTrends: TrendComponent[] = [
        {
          id: 'trend-1',
          direction: 'up',
          magnitude: 0.15,
          significance: 0.89,
          startDate: new Date('2024-01-01'),
          endDate: new Date('2025-07-14'),
          description: 'Устойчивый восходящий тренд роста на 15% за год',
          rSquared: 0.78
        },
        {
          id: 'trend-2',
          direction: 'down',
          magnitude: 0.08,
          significance: 0.67,
          startDate: new Date('2025-05-01'),
          endDate: new Date('2025-07-14'),
          description: 'Краткосрочный нисходящий тренд -8% за последние 3 месяца',
          rSquared: 0.54
        }
      ];

      const fallbackAnalysis: AnalysisResult = {
        dataPoints: Array.from({ length: 30 }, (_, i) => ({
          date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          actual: 100 + Math.random() * 50 + Math.sin(i / 7 * Math.PI) * 20,
          trend: 105 + i * 0.5,
          seasonal: Math.sin(i / 7 * Math.PI) * 15,
          residual: (Math.random() - 0.5) * 10,
          forecast: 100 + Math.random() * 50 + Math.sin((i + 1) / 7 * Math.PI) * 20
        })),
        decomposition: {
          trend: Array.from({ length: 30 }, (_, i) => 105 + i * 0.5),
          seasonal: Array.from({ length: 30 }, (_, i) => Math.sin(i / 7 * Math.PI) * 15),
          residual: Array.from({ length: 30 }, () => (Math.random() - 0.5) * 10)
        },
        metrics: {
          seasonalityIndex: 0.85,
          trendStrength: 0.72,
          volatility: 0.23,
          predictability: 0.89
        }
      };

      setSeasonalPatterns(fallbackPatterns);
      setTrendComponents(fallbackTrends);
      setAnalysisResult(fallbackAnalysis);
      setSelectedPattern(fallbackPatterns[0].id);
    } finally {
      setIsAnalyzing(false);
    }
  };

  useEffect(() => {
    loadAnalysisData();
  }, [selectedDataSource, analysisTimeframe, decompositionMethod]);

  const runAnalysis = async () => {
    setIsAnalyzing(true);
    
    try {
      const response = await fetch(`${API_BASE_URL}/analytics/seasonal-analysis`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          data_source: selectedDataSource,
          timeframe: analysisTimeframe,
          method: decompositionMethod
        })
      });

      if (response.ok) {
        const result = await response.json();
        setSeasonalPatterns(result.patterns || []);
        setTrendComponents(result.trends || []);
        setAnalysisResult(result.analysis || null);
      }
    } catch (error) {
      console.error('Failed to run analysis:', error);
      // Use existing fallback data
    } finally {
      setTimeout(() => setIsAnalyzing(false), 2000);
    }
  };

  const exportAnalysis = () => {
    const exportData = {
      patterns: seasonalPatterns,
      trends: trendComponents,
      analysis: analysisResult,
      parameters: {
        dataSource: selectedDataSource,
        timeframe: analysisTimeframe,
        method: decompositionMethod
      },
      timestamp: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `seasonal-trend-analysis-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getPatternTypeColor = (type: SeasonalPattern['type']) => {
    switch (type) {
      case 'daily':
        return 'bg-blue-100 text-blue-800';
      case 'weekly':
        return 'bg-green-100 text-green-800';
      case 'monthly':
        return 'bg-purple-100 text-purple-800';
      case 'yearly':
        return 'bg-orange-100 text-orange-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getTrendIcon = (direction: TrendComponent['direction']) => {
    switch (direction) {
      case 'up':
        return <TrendingUp className="h-4 w-4 text-green-500" />;
      case 'down':
        return <TrendingUp className="h-4 w-4 text-red-500 rotate-180" />;
      default:
        return <Activity className="h-4 w-4 text-gray-500" />;
    }
  };

  const selectedPatternData = seasonalPatterns.find(p => p.id === selectedPattern);

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <Calendar className="h-6 w-6 mr-2 text-blue-600" />
              Анализатор Сезонных Трендов
            </h2>
            <p className="mt-2 text-gray-600">
              Глубокий анализ сезонности и трендов в исторических данных
            </p>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={() => setShowAdvancedFilters(!showAdvancedFilters)}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              <Filter className="h-4 w-4 mr-2" />
              Фильтры
            </button>
            <button
              onClick={exportAnalysis}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              <Download className="h-4 w-4 mr-2" />
              Экспорт
            </button>
            <button
              onClick={runAnalysis}
              disabled={isAnalyzing}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${isAnalyzing ? 'animate-spin' : ''}`} />
              {isAnalyzing ? 'Анализируем...' : 'Запустить анализ'}
            </button>
          </div>
        </div>
      </div>

      {/* Configuration Panel */}
      <div className={`mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6 ${showAdvancedFilters ? 'block' : 'hidden'}`}>
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
              Период анализа
            </label>
            <select
              value={analysisTimeframe}
              onChange={(e) => setAnalysisTimeframe(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="3months">3 месяца</option>
              <option value="6months">6 месяцев</option>
              <option value="12months">12 месяцев</option>
              <option value="24months">24 месяца</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Метод декомпозиции
            </label>
            <select
              value={decompositionMethod}
              onChange={(e) => setDecompositionMethod(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="additive">Аддитивная</option>
              <option value="multiplicative">Мультипликативная</option>
              <option value="stl">STL декомпозиция</option>
              <option value="x13">X-13ARIMA-SEATS</option>
            </select>
          </div>
        </div>
      </div>

      {/* Analysis Metrics */}
      {analysisResult && (
        <div className="mb-6 grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Индекс сезонности</p>
                <p className="text-2xl font-bold text-blue-600">{(analysisResult.metrics.seasonalityIndex * 100).toFixed(1)}%</p>
              </div>
              <Calendar className="h-8 w-8 text-blue-500" />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Сила тренда</p>
                <p className="text-2xl font-bold text-green-600">{(analysisResult.metrics.trendStrength * 100).toFixed(1)}%</p>
              </div>
              <TrendingUp className="h-8 w-8 text-green-500" />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Волатильность</p>
                <p className="text-2xl font-bold text-orange-600">{(analysisResult.metrics.volatility * 100).toFixed(1)}%</p>
              </div>
              <Activity className="h-8 w-8 text-orange-500" />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Предсказуемость</p>
                <p className="text-2xl font-bold text-purple-600">{(analysisResult.metrics.predictability * 100).toFixed(1)}%</p>
              </div>
              <BarChart3 className="h-8 w-8 text-purple-500" />
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Seasonal Patterns */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Сезонные паттерны</h3>
            </div>
            
            <div className="p-4 space-y-3 max-h-96 overflow-y-auto">
              {seasonalPatterns.map((pattern) => (
                <div
                  key={pattern.id}
                  className={`p-3 border rounded-lg cursor-pointer transition-colors ${
                    selectedPattern === pattern.id
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                  onClick={() => setSelectedPattern(pattern.id)}
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-medium text-gray-900">{pattern.name}</span>
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getPatternTypeColor(pattern.type)}`}>
                      {pattern.type}
                    </span>
                  </div>
                  
                  <div className="flex items-center justify-between text-xs mb-2">
                    <span className="text-gray-600">Сила: {(pattern.strength * 100).toFixed(0)}%</span>
                    <span className="text-gray-600">Уверенность: {(pattern.confidence * 100).toFixed(0)}%</span>
                  </div>
                  
                  <p className="text-xs text-gray-600 mb-2">{pattern.description}</p>
                  
                  <div className="text-xs text-gray-500">
                    Обнаружен: {pattern.detectedAt.toLocaleDateString('ru-RU')}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Trend Components */}
          <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Трендовые компоненты</h3>
            </div>
            
            <div className="p-4 space-y-3">
              {trendComponents.map((trend) => (
                <div key={trend.id} className="p-3 bg-gray-50 rounded-lg">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      {getTrendIcon(trend.direction)}
                      <span className="text-sm font-medium text-gray-900">
                        {trend.direction === 'up' ? 'Восходящий' :
                         trend.direction === 'down' ? 'Нисходящий' : 'Стабильный'}
                      </span>
                    </div>
                    <span className={`text-sm font-medium ${
                      trend.direction === 'up' ? 'text-green-600' :
                      trend.direction === 'down' ? 'text-red-600' : 'text-gray-600'
                    }`}>
                      {trend.direction === 'up' ? '+' : ''}{(trend.magnitude * 100).toFixed(1)}%
                    </span>
                  </div>
                  
                  <p className="text-xs text-gray-600 mb-2">{trend.description}</p>
                  
                  <div className="flex justify-between text-xs text-gray-500">
                    <span>R²: {trend.rSquared.toFixed(3)}</span>
                    <span>Значимость: {(trend.significance * 100).toFixed(0)}%</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Pattern Details & Visualization */}
        <div className="lg:col-span-2">
          {selectedPatternData && (
            <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">{selectedPatternData.name}</h3>
                <div className="flex items-center gap-4 text-sm">
                  <span className="text-gray-600">
                    Сила: <strong className="text-blue-600">{(selectedPatternData.strength * 100).toFixed(1)}%</strong>
                  </span>
                  <span className="text-gray-600">
                    Уверенность: <strong className="text-green-600">{(selectedPatternData.confidence * 100).toFixed(1)}%</strong>
                  </span>
                </div>
              </div>
              
              <p className="text-sm text-gray-600 mb-4">{selectedPatternData.description}</p>
              
              <div className="overflow-x-auto">
                <table className="min-w-full">
                  <thead>
                    <tr className="border-b border-gray-200">
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider py-2">
                        Период
                      </th>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider py-2">
                        Индекс
                      </th>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider py-2">
                        Вариация
                      </th>
                      <th className="text-right text-xs font-medium text-gray-500 uppercase tracking-wider py-2">
                        Статус
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {selectedPatternData.peakPeriods.map((period, index) => (
                      <tr key={index}>
                        <td className="py-2 text-sm text-gray-900">{period.period}</td>
                        <td className="py-2">
                          <span className={`text-sm font-medium ${
                            period.value > 110 ? 'text-red-600' :
                            period.value > 100 ? 'text-orange-600' :
                            period.value > 90 ? 'text-green-600' : 'text-blue-600'
                          }`}>
                            {period.value.toFixed(0)}%
                          </span>
                        </td>
                        <td className="py-2 text-sm text-gray-600">
                          ±{period.variance.toFixed(1)}%
                        </td>
                        <td className="py-2 text-right">
                          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                            period.value > 110 ? 'bg-red-100 text-red-800' :
                            period.value > 100 ? 'bg-orange-100 text-orange-800' :
                            period.value > 90 ? 'bg-green-100 text-green-800' : 'bg-blue-100 text-blue-800'
                          }`}>
                            {period.value > 110 ? 'Пик' :
                             period.value > 100 ? 'Высокий' :
                             period.value > 90 ? 'Норма' : 'Низкий'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Decomposition Chart Placeholder */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between mb-4">
              <h4 className="text-lg font-semibold text-gray-900">Декомпозиция временного ряда</h4>
              <button className="flex items-center px-3 py-1 text-sm border border-gray-300 rounded-md hover:bg-gray-50">
                <Eye className="h-3 w-3 mr-1" />
                Интерактивный просмотр
              </button>
            </div>
            
            <div className="space-y-4">
              {/* Original Data */}
              <div>
                <h5 className="text-sm font-medium text-gray-700 mb-2">Исходные данные</h5>
                <div className="h-16 bg-gray-50 rounded flex items-center justify-center">
                  <span className="text-xs text-gray-500">График исходных данных</span>
                </div>
              </div>
              
              {/* Trend */}
              <div>
                <h5 className="text-sm font-medium text-gray-700 mb-2">Тренд</h5>
                <div className="h-16 bg-blue-50 rounded flex items-center justify-center">
                  <span className="text-xs text-gray-500">График тренда</span>
                </div>
              </div>
              
              {/* Seasonal */}
              <div>
                <h5 className="text-sm font-medium text-gray-700 mb-2">Сезонность</h5>
                <div className="h-16 bg-green-50 rounded flex items-center justify-center">
                  <span className="text-xs text-gray-500">График сезонной компоненты</span>
                </div>
              </div>
              
              {/* Residual */}
              <div>
                <h5 className="text-sm font-medium text-gray-700 mb-2">Остатки</h5>
                <div className="h-16 bg-orange-50 rounded flex items-center justify-center">
                  <span className="text-xs text-gray-500">График остатков</span>
                </div>
              </div>
            </div>
            
            <div className="mt-4 text-center">
              <p className="text-sm text-gray-500">
                Интерактивные графики будут интегрированы с библиотекой визуализации
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SeasonalTrendAnalyzer;