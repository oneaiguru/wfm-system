import React, { useState, useEffect } from 'react';
import { Target, TrendingUp, TrendingDown, AlertTriangle, CheckCircle, BarChart3, Calendar, Download } from 'lucide-react';

interface ForecastAccuracyProps {
  forecastId?: string;
  timeRange?: 'week' | 'month' | 'quarter' | 'year';
  category?: 'call_volume' | 'aht' | 'service_level' | 'staffing';
}

interface AccuracyMetric {
  date: Date;
  predicted: number;
  actual: number;
  absoluteError: number;
  percentageError: number;
  accuracy: number;
}

interface AccuracySummary {
  mape: number; // Mean Absolute Percentage Error
  rmse: number; // Root Mean Square Error
  mae: number; // Mean Absolute Error
  r2: number; // R-squared
  accuracy: number;
  trend: 'improving' | 'declining' | 'stable';
  totalDataPoints: number;
  period: string;
}

interface AccuracyBenchmark {
  category: string;
  targetAccuracy: number;
  currentAccuracy: number;
  threshold: 'excellent' | 'good' | 'fair' | 'poor';
  recommendation: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

// Russian translations
const translations = {
  title: 'Точность прогнозов',
  subtitle: 'Анализ качества прогнозирования',
  metrics: {
    mape: 'Средняя абсолютная ошибка в %',
    rmse: 'Среднеквадратичная ошибка',
    mae: 'Средняя абсолютная ошибка',
    r2: 'Коэффициент детерминации',
    accuracy: 'Общая точность',
    trend: 'Тенденция точности',
    totalDataPoints: 'Точек данных',
    period: 'Период анализа'
  },
  categories: {
    call_volume: 'Объем звонков',
    aht: 'Время обработки',
    service_level: 'Уровень сервиса',
    staffing: 'Штатное расписание'
  },
  timeRanges: {
    week: 'Неделя',
    month: 'Месяц',
    quarter: 'Квартал',
    year: 'Год'
  },
  trends: {
    improving: 'Улучшается',
    declining: 'Ухудшается',
    stable: 'Стабильная'
  },
  thresholds: {
    excellent: 'Отлично',
    good: 'Хорошо',
    fair: 'Удовлетворительно',
    poor: 'Неудовлетворительно'
  },
  benchmarks: {
    title: 'Бенчмарки качества',
    target: 'Цель',
    current: 'Текущий',
    status: 'Статус',
    recommendation: 'Рекомендация'
  },
  chart: {
    predicted: 'Прогноз',
    actual: 'Фактические данные',
    errorBand: 'Полоса ошибок',
    accuracy: 'Точность',
    error: 'Ошибка'
  },
  actions: {
    export: 'Экспорт',
    refresh: 'Обновить',
    analyze: 'Анализировать',
    viewDetails: 'Подробности'
  },
  insights: {
    title: 'Выводы и рекомендации',
    accuracyTrend: 'Тренд точности',
    keyFindings: 'Основные выводы',
    recommendations: 'Рекомендации'
  },
  noData: 'Нет данных для анализа',
  loading: 'Загрузка данных о точности...',
  error: 'Ошибка загрузки данных'
};

const ForecastAccuracy: React.FC<ForecastAccuracyProps> = ({
  forecastId,
  timeRange = 'month',
  category = 'call_volume'
}) => {
  const [accuracyData, setAccuracyData] = useState<AccuracyMetric[]>([]);
  const [summary, setSummary] = useState<AccuracySummary | null>(null);
  const [benchmarks, setBenchmarks] = useState<AccuracyBenchmark[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState(category);
  const [selectedTimeRange, setSelectedTimeRange] = useState(timeRange);

  useEffect(() => {
    loadAccuracyData();
  }, [forecastId, selectedTimeRange, selectedCategory]);

  const loadAccuracyData = async () => {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(
        `${API_BASE_URL}/reports/forecast-accuracy?category=${selectedCategory}&time_range=${selectedTimeRange}${forecastId ? `&forecast_id=${forecastId}` : ''}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (response.ok) {
        const data = await response.json();

        // Map accuracy data
        const mappedData = (data.accuracy_data || []).map((item: any) => ({
          date: new Date(item.date),
          predicted: item.predicted,
          actual: item.actual,
          absoluteError: Math.abs(item.actual - item.predicted),
          percentageError: item.actual !== 0 ? Math.abs((item.actual - item.predicted) / item.actual) * 100 : 0,
          accuracy: item.actual !== 0 ? Math.max(0, 100 - Math.abs((item.actual - item.predicted) / item.actual) * 100) : 0
        }));

        setAccuracyData(mappedData);

        // Set summary
        if (data.summary) {
          setSummary({
            mape: data.summary.mape || 0,
            rmse: data.summary.rmse || 0,
            mae: data.summary.mae || 0,
            r2: data.summary.r2 || 0,
            accuracy: data.summary.accuracy || 0,
            trend: data.summary.trend || 'stable',
            totalDataPoints: data.summary.total_data_points || 0,
            period: data.summary.period || selectedTimeRange
          });
        }

        // Set benchmarks
        setBenchmarks((data.benchmarks || []).map((benchmark: any) => ({
          category: benchmark.category,
          targetAccuracy: benchmark.target_accuracy,
          currentAccuracy: benchmark.current_accuracy,
          threshold: benchmark.threshold,
          recommendation: benchmark.recommendation
        })));

      } else {
        throw new Error('Failed to load accuracy data');
      }
    } catch (error) {
      console.error('Error loading accuracy data:', error);
      setError(translations.error);
    } finally {
      setLoading(false);
    }
  };

  const exportAccuracyReport = async () => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/reports/forecast-accuracy/export?category=${selectedCategory}&time_range=${selectedTimeRange}&format=xlsx`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `forecast_accuracy_${selectedCategory}_${selectedTimeRange}.xlsx`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      }
    } catch (error) {
      console.error('Error exporting accuracy report:', error);
    }
  };

  const getAccuracyColor = (accuracy: number) => {
    if (accuracy >= 90) return 'text-green-600';
    if (accuracy >= 75) return 'text-yellow-600';
    if (accuracy >= 60) return 'text-orange-600';
    return 'text-red-600';
  };

  const getThresholdColor = (threshold: string) => {
    switch (threshold) {
      case 'excellent': return 'bg-green-100 text-green-800';
      case 'good': return 'bg-blue-100 text-blue-800';
      case 'fair': return 'bg-yellow-100 text-yellow-800';
      case 'poor': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'improving':
        return <TrendingUp className="h-4 w-4 text-green-600" />;
      case 'declining':
        return <TrendingDown className="h-4 w-4 text-red-600" />;
      default:
        return <BarChart3 className="h-4 w-4 text-gray-600" />;
    }
  };

  const renderAccuracyChart = () => {
    if (accuracyData.length === 0) {
      return (
        <div className="h-64 flex items-center justify-center text-gray-500">
          {translations.noData}
        </div>
      );
    }

    const maxValue = Math.max(...accuracyData.map(d => Math.max(d.predicted, d.actual)));
    const chartHeight = 200;
    const chartWidth = 600;
    const padding = { top: 20, right: 50, bottom: 40, left: 50 };

    return (
      <div className="relative">
        <svg width={chartWidth} height={chartHeight + padding.top + padding.bottom} className="w-full">
          {/* Grid lines */}
          <defs>
            <pattern id="grid" width="40" height="20" patternUnits="userSpaceOnUse">
              <path d="M 40 0 L 0 0 0 20" fill="none" stroke="#e5e7eb" strokeWidth="1"/>
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#grid)" />

          {/* Chart area */}
          <g transform={`translate(${padding.left}, ${padding.top})`}>
            {/* Predicted line */}
            <path
              d={accuracyData.map((point, index) => {
                const x = (index / (accuracyData.length - 1)) * (chartWidth - padding.left - padding.right);
                const y = chartHeight - (point.predicted / maxValue) * chartHeight;
                return `${index === 0 ? 'M' : 'L'} ${x} ${y}`;
              }).join(' ')}
              stroke="#3b82f6"
              strokeWidth="2"
              fill="none"
            />

            {/* Actual line */}
            <path
              d={accuracyData.map((point, index) => {
                const x = (index / (accuracyData.length - 1)) * (chartWidth - padding.left - padding.right);
                const y = chartHeight - (point.actual / maxValue) * chartHeight;
                return `${index === 0 ? 'M' : 'L'} ${x} ${y}`;
              }).join(' ')}
              stroke="#10b981"
              strokeWidth="2"
              fill="none"
            />

            {/* Error bars */}
            {accuracyData.map((point, index) => {
              const x = (index / (accuracyData.length - 1)) * (chartWidth - padding.left - padding.right);
              const predictedY = chartHeight - (point.predicted / maxValue) * chartHeight;
              const actualY = chartHeight - (point.actual / maxValue) * chartHeight;
              
              return (
                <line
                  key={index}
                  x1={x}
                  y1={predictedY}
                  x2={x}
                  y2={actualY}
                  stroke="#f59e0b"
                  strokeWidth="1"
                  opacity="0.5"
                />
              );
            })}

            {/* Data points */}
            {accuracyData.map((point, index) => {
              const x = (index / (accuracyData.length - 1)) * (chartWidth - padding.left - padding.right);
              const predictedY = chartHeight - (point.predicted / maxValue) * chartHeight;
              const actualY = chartHeight - (point.actual / maxValue) * chartHeight;
              
              return (
                <g key={index}>
                  <circle
                    cx={x}
                    cy={predictedY}
                    r="3"
                    fill="#3b82f6"
                    className="hover:r-4 transition-all cursor-pointer"
                  />
                  <circle
                    cx={x}
                    cy={actualY}
                    r="3"
                    fill="#10b981"
                    className="hover:r-4 transition-all cursor-pointer"
                  />
                </g>
              );
            })}
          </g>

          {/* X-axis labels */}
          <g transform={`translate(${padding.left}, ${chartHeight + padding.top + 20})`}>
            {accuracyData.map((point, index) => {
              if (index % Math.ceil(accuracyData.length / 6) === 0) {
                const x = (index / (accuracyData.length - 1)) * (chartWidth - padding.left - padding.right);
                return (
                  <text
                    key={index}
                    x={x}
                    y={0}
                    textAnchor="middle"
                    className="text-xs fill-gray-600"
                  >
                    {point.date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' })}
                  </text>
                );
              }
              return null;
            })}
          </g>

          {/* Y-axis labels */}
          <g transform={`translate(${padding.left - 10}, ${padding.top})`}>
            {Array.from({ length: 5 }, (_, i) => {
              const value = (maxValue / 4) * (4 - i);
              const y = (chartHeight / 4) * i;
              return (
                <text
                  key={i}
                  x={0}
                  y={y}
                  textAnchor="end"
                  className="text-xs fill-gray-600"
                >
                  {Math.round(value)}
                </text>
              );
            })}
          </g>
        </svg>

        {/* Legend */}
        <div className="flex justify-center gap-6 mt-4">
          <div className="flex items-center gap-2">
            <div className="w-4 h-0.5 bg-blue-600"></div>
            <span className="text-sm text-gray-600">{translations.chart.predicted}</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-0.5 bg-green-600"></div>
            <span className="text-sm text-gray-600">{translations.chart.actual}</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-0.5 bg-yellow-600"></div>
            <span className="text-sm text-gray-600">{translations.chart.error}</span>
          </div>
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-300 rounded w-1/3"></div>
          <div className="h-64 bg-gray-300 rounded"></div>
          <div className="grid grid-cols-2 gap-4">
            <div className="h-32 bg-gray-300 rounded"></div>
            <div className="h-32 bg-gray-300 rounded"></div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="text-center py-12">
          <AlertTriangle className="h-12 w-12 text-red-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">{translations.error}</h3>
          <p className="text-gray-500 mb-4">{error}</p>
          <button
            onClick={loadAccuracyData}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            {translations.actions.refresh}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200" data-testid="forecast-accuracy">
      {/* Header */}
      <div className="border-b border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Target className="h-6 w-6 text-blue-600" />
            <div>
              <h3 className="text-lg font-semibold text-gray-900">{translations.title}</h3>
              <p className="text-sm text-gray-600">{translations.subtitle}</p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            {/* Category Filter */}
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value as any)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              {Object.entries(translations.categories).map(([key, label]) => (
                <option key={key} value={key}>{label}</option>
              ))}
            </select>

            {/* Time Range Filter */}
            <select
              value={selectedTimeRange}
              onChange={(e) => setSelectedTimeRange(e.target.value as any)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              {Object.entries(translations.timeRanges).map(([key, label]) => (
                <option key={key} value={key}>{label}</option>
              ))}
            </select>

            {/* Actions */}
            <div className="flex items-center gap-2">
              <button
                onClick={exportAccuracyReport}
                className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
                title={translations.actions.export}
              >
                <Download className="h-5 w-5" />
              </button>
              <button
                onClick={loadAccuracyData}
                className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
                title={translations.actions.refresh}
              >
                <Calendar className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Summary Metrics */}
      {summary && (
        <div className="border-b border-gray-200 p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-blue-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <Target className="h-5 w-5 text-blue-600" />
                <span className="text-sm font-medium text-blue-900">{translations.metrics.accuracy}</span>
              </div>
              <div className={`text-2xl font-bold ${getAccuracyColor(summary.accuracy)}`}>
                {Math.round(summary.accuracy)}%
              </div>
            </div>
            
            <div className="bg-green-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <BarChart3 className="h-5 w-5 text-green-600" />
                <span className="text-sm font-medium text-green-900">{translations.metrics.mape}</span>
              </div>
              <div className="text-2xl font-bold text-green-900">
                {Math.round(summary.mape * 100) / 100}%
              </div>
            </div>
            
            <div className="bg-purple-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                {getTrendIcon(summary.trend)}
                <span className="text-sm font-medium text-purple-900">{translations.metrics.trend}</span>
              </div>
              <div className="text-lg font-bold text-purple-900">
                {translations.trends[summary.trend as keyof typeof translations.trends]}
              </div>
            </div>
            
            <div className="bg-orange-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <CheckCircle className="h-5 w-5 text-orange-600" />
                <span className="text-sm font-medium text-orange-900">{translations.metrics.r2}</span>
              </div>
              <div className="text-2xl font-bold text-orange-900">
                {Math.round(summary.r2 * 100) / 100}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Accuracy Chart */}
      <div className="border-b border-gray-200 p-6">
        <h4 className="text-md font-semibold text-gray-900 mb-4">Сравнение прогноза и фактических данных</h4>
        {renderAccuracyChart()}
      </div>

      {/* Benchmarks */}
      <div className="p-6">
        <h4 className="text-md font-semibold text-gray-900 mb-4">{translations.benchmarks.title}</h4>
        
        {benchmarks.length > 0 ? (
          <div className="space-y-4">
            {benchmarks.map((benchmark, index) => (
              <div key={index} className="bg-gray-50 rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <h5 className="font-medium text-gray-900">
                    {translations.categories[benchmark.category as keyof typeof translations.categories]}
                  </h5>
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${getThresholdColor(benchmark.threshold)}`}>
                    {translations.thresholds[benchmark.threshold as keyof typeof translations.thresholds]}
                  </span>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-3">
                  <div>
                    <span className="text-sm text-gray-600">{translations.benchmarks.target}: </span>
                    <span className="font-medium text-gray-900">{benchmark.targetAccuracy}%</span>
                  </div>
                  <div>
                    <span className="text-sm text-gray-600">{translations.benchmarks.current}: </span>
                    <span className={`font-medium ${getAccuracyColor(benchmark.currentAccuracy)}`}>
                      {benchmark.currentAccuracy}%
                    </span>
                  </div>
                </div>
                
                <div className="text-sm text-gray-700">
                  <strong>{translations.benchmarks.recommendation}:</strong> {benchmark.recommendation}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            {translations.noData}
          </div>
        )}
      </div>
    </div>
  );
};

export default ForecastAccuracy;