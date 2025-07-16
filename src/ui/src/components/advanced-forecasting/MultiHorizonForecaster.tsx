import React, { useState, useEffect } from 'react';
import { Clock, Layers, BarChart3, Calendar, Play, Download, Settings, TrendingUp } from 'lucide-react';

interface ForecastHorizon {
  id: string;
  name: string;
  period: 'short' | 'medium' | 'long';
  duration: number;
  durationUnit: 'hours' | 'days' | 'weeks' | 'months';
  description: string;
  enabled: boolean;
  confidence: number;
  updateFrequency: string;
}

interface MultiHorizonForecast {
  date: string;
  horizons: {
    [horizonId: string]: {
      predicted: number;
      confidence_lower: number;
      confidence_upper: number;
      accuracy: number;
      lastUpdated: Date;
    };
  };
  actual?: number;
}

interface HorizonComparison {
  metric: string;
  horizons: Array<{
    horizonId: string;
    value: number;
    rank: number;
  }>;
}

interface ForecastParameters {
  algorithm: 'ensemble' | 'arima' | 'neural' | 'exponential' | 'prophet';
  seasonality: boolean;
  trend: boolean;
  externalFactors: boolean;
  confidenceLevel: number;
  dataQualityThreshold: number;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const MultiHorizonForecaster: React.FC = () => {
  const [horizons, setHorizons] = useState<ForecastHorizon[]>([]);
  const [forecasts, setForecasts] = useState<MultiHorizonForecast[]>([]);
  const [comparisons, setComparisons] = useState<HorizonComparison[]>([]);
  const [parameters, setParameters] = useState<ForecastParameters>({
    algorithm: 'ensemble',
    seasonality: true,
    trend: true,
    externalFactors: false,
    confidenceLevel: 95,
    dataQualityThreshold: 85
  });
  const [selectedHorizons, setSelectedHorizons] = useState<string[]>([]);
  const [isForecasting, setIsForecasting] = useState(false);
  const [forecastProgress, setForecastProgress] = useState<{[key: string]: number}>({});
  const [showSettings, setShowSettings] = useState(false);

  const loadForecastData = async () => {
    try {
      console.log('[MULTI HORIZON] Loading multi-horizon forecast data...');

      // Load available horizons
      const horizonsResponse = await fetch(`${API_BASE_URL}/forecasting/horizons`);
      if (!horizonsResponse.ok) {
        throw new Error(`Horizons API failed: ${horizonsResponse.status}`);
      }

      const horizonsData = await horizonsResponse.json();
      const realHorizons = (horizonsData.horizons || []).map((horizon: any) => ({
        id: horizon.id || `horizon_${Date.now()}`,
        name: horizon.name || horizon.horizon_name,
        period: horizon.period || horizon.time_period || 'short',
        duration: horizon.duration || horizon.forecast_duration || 1,
        durationUnit: horizon.duration_unit || horizon.unit || 'days',
        description: horizon.description || horizon.summary || '',
        enabled: horizon.enabled !== undefined ? horizon.enabled : true,
        confidence: horizon.confidence || horizon.confidence_level || 95,
        updateFrequency: horizon.update_frequency || horizon.frequency || 'daily'
      }));

      setHorizons(realHorizons);

      if (realHorizons.length > 0 && selectedHorizons.length === 0) {
        setSelectedHorizons(realHorizons.slice(0, 3).map(h => h.id));
      }

      // Load existing forecasts
      const forecastsResponse = await fetch(`${API_BASE_URL}/forecasting/multi-horizon?horizons=${selectedHorizons.join(',')}`);
      if (forecastsResponse.ok) {
        const forecastsData = await forecastsResponse.json();
        setForecasts(forecastsData.forecasts || []);
      }

      // Load horizon comparisons
      const comparisonsResponse = await fetch(`${API_BASE_URL}/forecasting/horizon-comparisons?horizons=${selectedHorizons.join(',')}`);
      if (comparisonsResponse.ok) {
        const comparisonsData = await comparisonsResponse.json();
        setComparisons(comparisonsData.comparisons || []);
      }

      console.log(`[MULTI HORIZON] Loaded ${realHorizons.length} forecast horizons`);

    } catch (error) {
      console.error('[MULTI HORIZON] Error loading data:', error);

      // Fallback data for demo
      const fallbackHorizons: ForecastHorizon[] = [
        {
          id: 'intraday',
          name: 'Внутридневной',
          period: 'short',
          duration: 24,
          durationUnit: 'hours',
          description: 'Прогноз на следующие 24 часа с интервалом 1 час',
          enabled: true,
          confidence: 90,
          updateFrequency: 'hourly'
        },
        {
          id: 'daily',
          name: 'Ежедневный',
          period: 'short',
          duration: 7,
          durationUnit: 'days',
          description: 'Прогноз на следующие 7 дней с интервалом 1 день',
          enabled: true,
          confidence: 92,
          updateFrequency: 'daily'
        },
        {
          id: 'weekly',
          name: 'Еженедельный',
          period: 'medium',
          duration: 4,
          durationUnit: 'weeks',
          description: 'Прогноз на следующие 4 недели с интервалом 1 неделя',
          enabled: true,
          confidence: 88,
          updateFrequency: 'weekly'
        },
        {
          id: 'monthly',
          name: 'Ежемесячный',
          period: 'medium',
          duration: 6,
          durationUnit: 'months',
          description: 'Прогноз на следующие 6 месяцев с интервалом 1 месяц',
          enabled: true,
          confidence: 82,
          updateFrequency: 'monthly'
        },
        {
          id: 'quarterly',
          name: 'Квартальный',
          period: 'long',
          duration: 8,
          durationUnit: 'months',
          description: 'Прогноз на следующие 2 года с интервалом 1 квартал',
          enabled: false,
          confidence: 75,
          updateFrequency: 'quarterly'
        },
        {
          id: 'annual',
          name: 'Годовой',
          period: 'long',
          duration: 3,
          durationUnit: 'months',
          description: 'Стратегический прогноз на 3 года с интервалом 1 год',
          enabled: false,
          confidence: 68,
          updateFrequency: 'annually'
        }
      ];

      const fallbackForecasts: MultiHorizonForecast[] = Array.from({ length: 30 }, (_, i) => {
        const date = new Date(Date.now() + i * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        const baseValue = 150 + Math.sin(i / 7 * Math.PI) * 30 + i * 0.5;
        
        return {
          date,
          horizons: {
            'intraday': {
              predicted: baseValue + Math.random() * 20 - 10,
              confidence_lower: baseValue - 15,
              confidence_upper: baseValue + 15,
              accuracy: 90 + Math.random() * 8,
              lastUpdated: new Date(Date.now() - Math.random() * 3600000)
            },
            'daily': {
              predicted: baseValue + Math.random() * 30 - 15,
              confidence_lower: baseValue - 25,
              confidence_upper: baseValue + 25,
              accuracy: 88 + Math.random() * 10,
              lastUpdated: new Date(Date.now() - Math.random() * 86400000)
            },
            'weekly': {
              predicted: baseValue + Math.random() * 40 - 20,
              confidence_lower: baseValue - 35,
              confidence_upper: baseValue + 35,
              accuracy: 85 + Math.random() * 8,
              lastUpdated: new Date(Date.now() - Math.random() * 604800000)
            },
            'monthly': {
              predicted: baseValue + Math.random() * 50 - 25,
              confidence_lower: baseValue - 45,
              confidence_upper: baseValue + 45,
              accuracy: 80 + Math.random() * 10,
              lastUpdated: new Date(Date.now() - Math.random() * 2592000000)
            }
          },
          actual: i < 7 ? baseValue + Math.random() * 10 - 5 : undefined
        };
      });

      const fallbackComparisons: HorizonComparison[] = [
        {
          metric: 'Средняя точность',
          horizons: [
            { horizonId: 'intraday', value: 92.3, rank: 1 },
            { horizonId: 'daily', value: 89.7, rank: 2 },
            { horizonId: 'weekly', value: 86.1, rank: 3 },
            { horizonId: 'monthly', value: 81.5, rank: 4 }
          ]
        },
        {
          metric: 'MAPE',
          horizons: [
            { horizonId: 'intraday', value: 7.2, rank: 1 },
            { horizonId: 'daily', value: 9.8, rank: 2 },
            { horizonId: 'weekly', value: 12.4, rank: 3 },
            { horizonId: 'monthly', value: 16.7, rank: 4 }
          ]
        },
        {
          metric: 'Стабильность',
          horizons: [
            { horizonId: 'intraday', value: 94.1, rank: 1 },
            { horizonId: 'daily', value: 91.8, rank: 2 },
            { horizonId: 'weekly', value: 87.3, rank: 3 },
            { horizonId: 'monthly', value: 83.6, rank: 4 }
          ]
        }
      ];

      setHorizons(fallbackHorizons);
      setForecasts(fallbackForecasts);
      setComparisons(fallbackComparisons);
      setSelectedHorizons(['intraday', 'daily', 'weekly', 'monthly']);
    }
  };

  useEffect(() => {
    loadForecastData();
  }, []);

  const runMultiHorizonForecast = async () => {
    if (selectedHorizons.length === 0) return;

    setIsForecasting(true);
    setForecastProgress({});

    try {
      // Simulate progress for each horizon
      const progressPromises = selectedHorizons.map(async (horizonId) => {
        const horizon = horizons.find(h => h.id === horizonId);
        if (!horizon) return;

        let progress = 0;
        const progressInterval = setInterval(() => {
          progress += Math.random() * 20;
          if (progress >= 100) {
            progress = 100;
            clearInterval(progressInterval);
          }
          setForecastProgress(prev => ({ ...prev, [horizonId]: progress }));
        }, 500);

        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 3000 + Math.random() * 2000));
        clearInterval(progressInterval);
        setForecastProgress(prev => ({ ...prev, [horizonId]: 100 }));
      });

      const response = await fetch(`${API_BASE_URL}/forecasting/run-multi-horizon`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          horizons: selectedHorizons,
          parameters
        })
      });

      if (response.ok) {
        const result = await response.json();
        setForecasts(result.forecasts || []);
        setComparisons(result.comparisons || []);
      }

      await Promise.all(progressPromises);

    } catch (error) {
      console.error('Failed to run multi-horizon forecast:', error);
      // Update with mock data
      await loadForecastData();
    } finally {
      setTimeout(() => {
        setIsForecasting(false);
        setForecastProgress({});
      }, 1000);
    }
  };

  const exportForecasts = () => {
    const exportData = {
      horizons: horizons.filter(h => selectedHorizons.includes(h.id)),
      forecasts,
      comparisons,
      parameters,
      generatedAt: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `multi-horizon-forecasts-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getPeriodColor = (period: ForecastHorizon['period']) => {
    switch (period) {
      case 'short':
        return 'bg-green-100 text-green-800';
      case 'medium':
        return 'bg-blue-100 text-blue-800';
      case 'long':
        return 'bg-purple-100 text-purple-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatDuration = (duration: number, unit: string) => {
    const unitMap = {
      'hours': 'ч',
      'days': 'дн',
      'weeks': 'нед',
      'months': 'мес'
    };
    return `${duration} ${unitMap[unit as keyof typeof unitMap] || unit}`;
  };

  const getAccuracyColor = (accuracy: number) => {
    if (accuracy >= 90) return 'text-green-600';
    if (accuracy >= 80) return 'text-yellow-600';
    return 'text-red-600';
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <Clock className="h-6 w-6 mr-2 text-blue-600" />
              Мультигоризонтный Прогнозировщик
            </h2>
            <p className="mt-2 text-gray-600">
              Одновременное прогнозирование на различные временные горизонты
            </p>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={() => setShowSettings(!showSettings)}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              <Settings className="h-4 w-4 mr-2" />
              Настройки
            </button>
            <button
              onClick={exportForecasts}
              disabled={forecasts.length === 0}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
            >
              <Download className="h-4 w-4 mr-2" />
              Экспорт
            </button>
            <button
              onClick={runMultiHorizonForecast}
              disabled={isForecasting || selectedHorizons.length === 0}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              <Play className="h-4 w-4 mr-2" />
              {isForecasting ? 'Прогнозирование...' : 'Запустить прогноз'}
            </button>
          </div>
        </div>
      </div>

      {/* Settings Panel */}
      {showSettings && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Параметры прогнозирования</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Алгоритм
              </label>
              <select
                value={parameters.algorithm}
                onChange={(e) => setParameters(prev => ({ ...prev, algorithm: e.target.value as any }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="ensemble">Ансамбль</option>
                <option value="arima">ARIMA</option>
                <option value="neural">Нейронная сеть</option>
                <option value="exponential">Экспоненциальное сглаживание</option>
                <option value="prophet">Prophet</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Уровень доверия (%)
              </label>
              <select
                value={parameters.confidenceLevel}
                onChange={(e) => setParameters(prev => ({ ...prev, confidenceLevel: Number(e.target.value) }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value={90}>90%</option>
                <option value={95}>95%</option>
                <option value={99}>99%</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Мин. качество данных (%)
              </label>
              <input
                type="number"
                min="0"
                max="100"
                value={parameters.dataQualityThreshold}
                onChange={(e) => setParameters(prev => ({ ...prev, dataQualityThreshold: Number(e.target.value) }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
          
          <div className="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={parameters.seasonality}
                onChange={(e) => setParameters(prev => ({ ...prev, seasonality: e.target.checked }))}
                className="rounded mr-2"
              />
              <span className="text-sm text-gray-700">Учитывать сезонность</span>
            </label>
            
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={parameters.trend}
                onChange={(e) => setParameters(prev => ({ ...prev, trend: e.target.checked }))}
                className="rounded mr-2"
              />
              <span className="text-sm text-gray-700">Учитывать тренд</span>
            </label>
            
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={parameters.externalFactors}
                onChange={(e) => setParameters(prev => ({ ...prev, externalFactors: e.target.checked }))}
                className="rounded mr-2"
              />
              <span className="text-sm text-gray-700">Внешние факторы</span>
            </label>
          </div>
        </div>
      )}

      {/* Forecast Progress */}
      {isForecasting && Object.keys(forecastProgress).length > 0 && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Прогресс прогнозирования</h3>
          <div className="space-y-4">
            {selectedHorizons.map(horizonId => {
              const horizon = horizons.find(h => h.id === horizonId);
              const progress = forecastProgress[horizonId] || 0;
              return (
                <div key={horizonId}>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-medium text-gray-700">{horizon?.name}</span>
                    <span className="text-sm text-gray-500">{progress.toFixed(0)}%</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                      style={{ width: `${progress}%` }}
                    ></div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Horizons Selection */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Горизонты прогнозирования</h3>
            </div>
            
            <div className="p-4 space-y-3">
              {horizons.map((horizon) => (
                <div
                  key={horizon.id}
                  className={`p-3 border rounded-lg transition-colors ${
                    selectedHorizons.includes(horizon.id)
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <label className="flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={selectedHorizons.includes(horizon.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedHorizons(prev => [...prev, horizon.id]);
                          } else {
                            setSelectedHorizons(prev => prev.filter(id => id !== horizon.id));
                          }
                        }}
                        className="mr-2 rounded"
                      />
                      <span className="text-sm font-medium text-gray-900">{horizon.name}</span>
                    </label>
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getPeriodColor(horizon.period)}`}>
                      {horizon.period === 'short' ? 'Короткий' :
                       horizon.period === 'medium' ? 'Средний' : 'Длинный'}
                    </span>
                  </div>
                  
                  <p className="text-xs text-gray-600 mb-2">{horizon.description}</p>
                  
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div className="text-center p-1 bg-gray-50 rounded">
                      <div className="font-medium text-gray-900">{formatDuration(horizon.duration, horizon.durationUnit)}</div>
                      <div className="text-gray-500">Период</div>
                    </div>
                    <div className="text-center p-1 bg-gray-50 rounded">
                      <div className="font-medium text-gray-900">{horizon.confidence}%</div>
                      <div className="text-gray-500">Доверие</div>
                    </div>
                  </div>
                  
                  <div className="text-xs text-gray-500 mt-2">
                    Обновление: {horizon.updateFrequency === 'hourly' ? 'Ежечасно' :
                                horizon.updateFrequency === 'daily' ? 'Ежедневно' :
                                horizon.updateFrequency === 'weekly' ? 'Еженедельно' :
                                horizon.updateFrequency === 'monthly' ? 'Ежемесячно' :
                                horizon.updateFrequency === 'quarterly' ? 'Ежеквартально' : 'Ежегодно'}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Forecasts Display */}
        <div className="lg:col-span-3">
          {/* Horizon Comparison */}
          {comparisons.length > 0 && (
            <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200">
              <div className="px-6 py-4 border-b border-gray-200">
                <h3 className="text-lg font-semibold text-gray-900">Сравнение горизонтов</h3>
              </div>
              
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Метрика
                      </th>
                      {selectedHorizons.map(horizonId => {
                        const horizon = horizons.find(h => h.id === horizonId);
                        return (
                          <th key={horizonId} className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                            {horizon?.name}
                          </th>
                        );
                      })}
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {comparisons.map((comparison, index) => (
                      <tr key={index}>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {comparison.metric}
                        </td>
                        {selectedHorizons.map(horizonId => {
                          const horizonData = comparison.horizons.find(h => h.horizonId === horizonId);
                          const isGold = horizonData?.rank === 1;
                          return (
                            <td key={horizonId} className="px-6 py-4 whitespace-nowrap text-center">
                              <div className={`inline-flex items-center ${isGold ? 'font-bold text-yellow-600' : 'text-gray-900'}`}>
                                {isGold && <TrendingUp className="h-3 w-3 mr-1" />}
                                <span className="text-sm">
                                  {horizonData?.value?.toFixed(1) || '-'}
                                  {comparison.metric.includes('MAPE') ? '%' : 
                                   comparison.metric.includes('точность') ? '%' : ''}
                                </span>
                              </div>
                            </td>
                          );
                        })}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Forecasts Table */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Прогнозы по горизонтам</h3>
            </div>
            
            {forecasts.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Дата
                      </th>
                      <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Фактическое
                      </th>
                      {selectedHorizons.map(horizonId => {
                        const horizon = horizons.find(h => h.id === horizonId);
                        return (
                          <th key={horizonId} className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                            {horizon?.name}
                          </th>
                        );
                      })}
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {forecasts.slice(0, 14).map((forecast, index) => (
                      <tr key={index} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {new Date(forecast.date).toLocaleDateString('ru-RU')}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-center text-sm text-gray-900">
                          {forecast.actual ? forecast.actual.toFixed(0) : '-'}
                        </td>
                        {selectedHorizons.map(horizonId => {
                          const horizonForecast = forecast.horizons[horizonId];
                          return (
                            <td key={horizonId} className="px-6 py-4 whitespace-nowrap text-center">
                              {horizonForecast ? (
                                <div>
                                  <div className="text-sm font-medium text-blue-600">
                                    {horizonForecast.predicted.toFixed(0)}
                                  </div>
                                  <div className="text-xs text-gray-500">
                                    ({horizonForecast.confidence_lower.toFixed(0)} - {horizonForecast.confidence_upper.toFixed(0)})
                                  </div>
                                  <div className={`text-xs ${getAccuracyColor(horizonForecast.accuracy)}`}>
                                    {horizonForecast.accuracy.toFixed(1)}%
                                  </div>
                                </div>
                              ) : (
                                <span className="text-sm text-gray-400">-</span>
                              )}
                            </td>
                          );
                        })}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="p-8 text-center">
                <Layers className="h-12 w-12 mx-auto mb-4 text-gray-400" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Нет данных прогнозов
                </h3>
                <p className="text-gray-600 mb-4">
                  Выберите горизонты прогнозирования и нажмите "Запустить прогноз"
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Visualization Placeholder */}
      <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Визуализация мультигоризонтных прогнозов</h3>
        <div className="h-64 flex items-center justify-center bg-gray-50 rounded-lg">
          <div className="text-center text-gray-500">
            <BarChart3 className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>Интерактивные графики прогнозов</p>
            <p className="text-sm">Сравнение различных временных горизонтов на одном графике</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MultiHorizonForecaster;