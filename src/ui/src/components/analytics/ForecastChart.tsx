import React, { useState, useEffect } from 'react';
import { TrendingUp, TrendingDown, BarChart3, LineChart, Calendar, Download, Settings } from 'lucide-react';

interface ForecastChartProps {
  forecastId?: string;
  timeRange?: 'day' | 'week' | 'month' | 'quarter';
  chartType?: 'line' | 'bar' | 'area';
  showActual?: boolean;
}

interface ForecastData {
  timestamp: Date;
  predicted: number;
  actual?: number;
  confidence: number;
  trend: 'up' | 'down' | 'stable';
  category: 'call_volume' | 'aht' | 'service_level' | 'staffing';
}

interface ForecastMetrics {
  accuracy: number;
  mape: number; // Mean Absolute Percentage Error
  trend: 'improving' | 'declining' | 'stable';
  confidence: number;
  lastUpdated: Date;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

// Russian translations
const translations = {
  title: 'Прогнозирование',
  metrics: {
    accuracy: 'Точность',
    mape: 'Средняя абсолютная ошибка',
    trend: 'Тренд',
    confidence: 'Достоверность',
    lastUpdated: 'Последнее обновление'
  },
  timeRanges: {
    day: 'День',
    week: 'Неделя',
    month: 'Месяц',
    quarter: 'Квартал'
  },
  chartTypes: {
    line: 'Линейный',
    bar: 'Столбчатый',
    area: 'Область'
  },
  categories: {
    call_volume: 'Объем звонков',
    aht: 'Среднее время обработки',
    service_level: 'Уровень сервиса',
    staffing: 'Штатное расписание'
  },
  trends: {
    up: 'Рост',
    down: 'Снижение',
    stable: 'Стабильно',
    improving: 'Улучшение',
    declining: 'Ухудшение'
  },
  legend: {
    predicted: 'Прогноз',
    actual: 'Фактические данные',
    confidence: 'Доверительный интервал'
  },
  actions: {
    export: 'Экспорт',
    settings: 'Настройки',
    refresh: 'Обновить',
    viewDetails: 'Подробности'
  },
  noData: 'Нет данных для отображения',
  loading: 'Загрузка прогноза...'
};

const ForecastChart: React.FC<ForecastChartProps> = ({
  forecastId,
  timeRange = 'week',
  chartType = 'line',
  showActual = true
}) => {
  const [forecastData, setForecastData] = useState<ForecastData[]>([]);
  const [metrics, setMetrics] = useState<ForecastMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<'call_volume' | 'aht' | 'service_level' | 'staffing'>('call_volume');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadForecastData();
  }, [forecastId, timeRange, selectedCategory]);

  const loadForecastData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(
        `${API_BASE_URL}/forecasts/current?category=${selectedCategory}&time_range=${timeRange}${forecastId ? `&forecast_id=${forecastId}` : ''}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (response.ok) {
        const data = await response.json();
        
        // Map forecast data
        const mappedData = (data.forecast_data || []).map((item: any) => ({
          timestamp: new Date(item.timestamp),
          predicted: item.predicted,
          actual: item.actual,
          confidence: item.confidence || 0.85,
          trend: item.trend || 'stable',
          category: item.category || selectedCategory
        }));

        setForecastData(mappedData);

        // Set metrics
        if (data.metrics) {
          setMetrics({
            accuracy: data.metrics.accuracy || 0,
            mape: data.metrics.mape || 0,
            trend: data.metrics.trend || 'stable',
            confidence: data.metrics.confidence || 0.85,
            lastUpdated: new Date(data.metrics.last_updated || Date.now())
          });
        }
      } else {
        throw new Error('Failed to load forecast data');
      }
    } catch (error) {
      console.error('Error loading forecast data:', error);
      setError('Ошибка загрузки данных прогноза');
    } finally {
      setLoading(false);
    }
  };

  const exportForecast = async () => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/forecasts/export?category=${selectedCategory}&time_range=${timeRange}&format=csv`,
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
        a.download = `forecast_${selectedCategory}_${timeRange}.csv`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      }
    } catch (error) {
      console.error('Error exporting forecast:', error);
    }
  };

  const getMaxValue = () => {
    if (forecastData.length === 0) return 100;
    
    const maxPredicted = Math.max(...forecastData.map(d => d.predicted));
    const maxActual = showActual ? Math.max(...forecastData.map(d => d.actual || 0)) : 0;
    
    return Math.max(maxPredicted, maxActual) * 1.1;
  };

  const formatTimestamp = (date: Date) => {
    switch (timeRange) {
      case 'day':
        return date.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
      case 'week':
        return date.toLocaleDateString('ru-RU', { weekday: 'short', day: 'numeric' });
      case 'month':
        return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' });
      case 'quarter':
        return date.toLocaleDateString('ru-RU', { month: 'short', year: '2-digit' });
      default:
        return date.toLocaleDateString('ru-RU');
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up':
      case 'improving':
        return <TrendingUp className="h-4 w-4 text-green-600" />;
      case 'down':
      case 'declining':
        return <TrendingDown className="h-4 w-4 text-red-600" />;
      default:
        return <BarChart3 className="h-4 w-4 text-gray-600" />;
    }
  };

  const getTrendColor = (trend: string) => {
    switch (trend) {
      case 'up':
      case 'improving':
        return 'text-green-600';
      case 'down':
      case 'declining':
        return 'text-red-600';
      default:
        return 'text-gray-600';
    }
  };

  const renderChart = () => {
    if (forecastData.length === 0) {
      return (
        <div className="h-64 flex items-center justify-center text-gray-500">
          {translations.noData}
        </div>
      );
    }

    const maxValue = getMaxValue();
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
              d={forecastData.map((point, index) => {
                const x = (index / (forecastData.length - 1)) * (chartWidth - padding.left - padding.right);
                const y = chartHeight - (point.predicted / maxValue) * chartHeight;
                return `${index === 0 ? 'M' : 'L'} ${x} ${y}`;
              }).join(' ')}
              stroke="#3b82f6"
              strokeWidth="2"
              fill="none"
            />

            {/* Actual line */}
            {showActual && (
              <path
                d={forecastData.filter(p => p.actual !== undefined).map((point, index) => {
                  const x = (index / (forecastData.length - 1)) * (chartWidth - padding.left - padding.right);
                  const y = chartHeight - ((point.actual || 0) / maxValue) * chartHeight;
                  return `${index === 0 ? 'M' : 'L'} ${x} ${y}`;
                }).join(' ')}
                stroke="#10b981"
                strokeWidth="2"
                fill="none"
              />
            )}

            {/* Confidence interval */}
            <path
              d={forecastData.map((point, index) => {
                const x = (index / (forecastData.length - 1)) * (chartWidth - padding.left - padding.right);
                const upperY = chartHeight - ((point.predicted * (1 + (1 - point.confidence))) / maxValue) * chartHeight;
                const lowerY = chartHeight - ((point.predicted * (1 - (1 - point.confidence))) / maxValue) * chartHeight;
                return `${index === 0 ? 'M' : 'L'} ${x} ${upperY}`;
              }).join(' ')}
              stroke="#3b82f6"
              strokeWidth="1"
              fill="none"
              opacity="0.3"
            />

            {/* Data points */}
            {forecastData.map((point, index) => {
              const x = (index / (forecastData.length - 1)) * (chartWidth - padding.left - padding.right);
              const y = chartHeight - (point.predicted / maxValue) * chartHeight;
              
              return (
                <g key={index}>
                  <circle
                    cx={x}
                    cy={y}
                    r="3"
                    fill="#3b82f6"
                    className="hover:r-4 transition-all cursor-pointer"
                  />
                  {point.actual !== undefined && (
                    <circle
                      cx={x}
                      cy={chartHeight - ((point.actual || 0) / maxValue) * chartHeight}
                      r="3"
                      fill="#10b981"
                      className="hover:r-4 transition-all cursor-pointer"
                    />
                  )}
                </g>
              );
            })}
          </g>

          {/* X-axis labels */}
          <g transform={`translate(${padding.left}, ${chartHeight + padding.top + 20})`}>
            {forecastData.map((point, index) => {
              if (index % Math.ceil(forecastData.length / 6) === 0) {
                const x = (index / (forecastData.length - 1)) * (chartWidth - padding.left - padding.right);
                return (
                  <text
                    key={index}
                    x={x}
                    y={0}
                    textAnchor="middle"
                    className="text-xs fill-gray-600"
                  >
                    {formatTimestamp(point.timestamp)}
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
            <span className="text-sm text-gray-600">{translations.legend.predicted}</span>
          </div>
          {showActual && (
            <div className="flex items-center gap-2">
              <div className="w-4 h-0.5 bg-green-600"></div>
              <span className="text-sm text-gray-600">{translations.legend.actual}</span>
            </div>
          )}
          <div className="flex items-center gap-2">
            <div className="w-4 h-0.5 bg-blue-600 opacity-30"></div>
            <span className="text-sm text-gray-600">{translations.legend.confidence}</span>
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
          <div className="grid grid-cols-4 gap-4">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="h-16 bg-gray-300 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="text-center py-12">
          <TrendingDown className="h-12 w-12 text-red-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Ошибка загрузки</h3>
          <p className="text-gray-500 mb-4">{error}</p>
          <button
            onClick={loadForecastData}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Попробовать снова
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200" data-testid="forecast-chart">
      {/* Header */}
      <div className="border-b border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <LineChart className="h-6 w-6 text-blue-600" />
            <h3 className="text-lg font-semibold text-gray-900">{translations.title}</h3>
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
              value={timeRange}
              onChange={(e) => setSelectedCategory(e.target.value as any)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              {Object.entries(translations.timeRanges).map(([key, label]) => (
                <option key={key} value={key}>{label}</option>
              ))}
            </select>

            {/* Actions */}
            <div className="flex items-center gap-2">
              <button
                onClick={exportForecast}
                className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
                title={translations.actions.export}
              >
                <Download className="h-5 w-5" />
              </button>
              <button
                onClick={loadForecastData}
                className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
                title={translations.actions.refresh}
              >
                <BarChart3 className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Metrics */}
      {metrics && (
        <div className="border-b border-gray-200 p-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="bg-blue-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <BarChart3 className="h-5 w-5 text-blue-600" />
                <span className="text-sm font-medium text-blue-900">{translations.metrics.accuracy}</span>
              </div>
              <div className="text-2xl font-bold text-blue-900">{Math.round(metrics.accuracy * 100)}%</div>
            </div>
            
            <div className="bg-green-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <TrendingUp className="h-5 w-5 text-green-600" />
                <span className="text-sm font-medium text-green-900">{translations.metrics.mape}</span>
              </div>
              <div className="text-2xl font-bold text-green-900">{Math.round(metrics.mape * 100) / 100}%</div>
            </div>
            
            <div className="bg-purple-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                {getTrendIcon(metrics.trend)}
                <span className="text-sm font-medium text-purple-900">{translations.metrics.trend}</span>
              </div>
              <div className={`text-lg font-bold ${getTrendColor(metrics.trend)}`}>
                {translations.trends[metrics.trend as keyof typeof translations.trends]}
              </div>
            </div>
            
            <div className="bg-orange-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <Calendar className="h-5 w-5 text-orange-600" />
                <span className="text-sm font-medium text-orange-900">{translations.metrics.confidence}</span>
              </div>
              <div className="text-2xl font-bold text-orange-900">{Math.round(metrics.confidence * 100)}%</div>
            </div>
          </div>
          
          <div className="mt-4 text-sm text-gray-600">
            {translations.metrics.lastUpdated}: {metrics.lastUpdated.toLocaleString('ru-RU')}
          </div>
        </div>
      )}

      {/* Chart */}
      <div className="p-6">
        {renderChart()}
      </div>
    </div>
  );
};

export default ForecastChart;