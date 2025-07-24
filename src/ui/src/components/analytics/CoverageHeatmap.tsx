import React, { useState, useEffect, useMemo } from 'react';
import { 
  Calendar, Users, AlertTriangle, CheckCircle, 
  TrendingUp, TrendingDown, RefreshCw, Download,
  Filter, Clock, Target, Activity, Eye
} from 'lucide-react';
import realCoverageAnalysisService from '../../services/realCoverageAnalysisService';

interface CoverageHeatmapData {
  day: string;
  hour: number;
  coverage_percentage: number;
  agents_required: number;
  agents_available: number;
  service_level: number;
  status: 'optimal' | 'adequate' | 'shortage' | 'surplus';
  intensity: number; // 0-1 for heatmap coloring
}

interface CoverageGap {
  start_time: string;
  end_time: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  agents_short: number;
  impact_on_service_level: number;
  recommended_actions: string[];
}

interface CoverageAnalysisData {
  period_start: string;
  period_end: string;
  average_coverage: number;
  min_coverage: number;
  max_coverage: number;
  heatmap_data: CoverageHeatmapData[];
  coverage_gaps: CoverageGap[];
  service_level_forecast: number;
  last_updated: string;
}

const russianTranslations = {
  title: 'Тепловая карта покрытия',
  subtitle: 'Анализ покрытия смен по дням и часам',
  sections: {
    heatmap: 'Карта покрытия',
    gaps: 'Пробелы в покрытии',
    statistics: 'Статистика',
    recommendations: 'Рекомендации'
  },
  metrics: {
    avgCoverage: 'Среднее покрытие',
    minCoverage: 'Минимальное покрытие',
    maxCoverage: 'Максимальное покрытие',
    serviceLevelForecast: 'Прогноз уровня сервиса',
    criticalGaps: 'Критические пробелы',
    totalGaps: 'Всего пробелов'
  },
  status: {
    optimal: 'Оптимально',
    adequate: 'Адекватно',
    shortage: 'Нехватка',
    surplus: 'Избыток'
  },
  severity: {
    critical: 'Критический',
    high: 'Высокий',
    medium: 'Средний',
    low: 'Низкий'
  },
  actions: {
    refresh: 'Обновить',
    export: 'Экспорт',
    filter: 'Фильтр'
  },
  time: {
    days: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
    hours: Array.from({ length: 24 }, (_, i) => `${i}:00`)
  }
};

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

export const CoverageHeatmap: React.FC = () => {
  const [coverageData, setCoverageData] = useState<CoverageAnalysisData | null>(null);
  const [selectedPeriod, setSelectedPeriod] = useState<'7d' | '30d' | '90d'>('7d');
  const [selectedServiceId, setSelectedServiceId] = useState<number>(1);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string>('');
  const [hoveredCell, setHoveredCell] = useState<CoverageHeatmapData | null>(null);

  useEffect(() => {
    loadCoverageHeatmap();
  }, [selectedPeriod, selectedServiceId]);

  const loadCoverageHeatmap = async () => {
    if (coverageData) setRefreshing(true);
    else setLoading(true);
    
    setError('');

    try {
      console.log(`[COVERAGE] Loading coverage heatmap via service for service ${selectedServiceId}, period ${selectedPeriod}`);
      
      const data = await realCoverageAnalysisService.getCoverageHeatmap(selectedServiceId, selectedPeriod);
      console.log('✅ Coverage heatmap data loaded via service:', data);
      
      setCoverageData(data);
    } catch (err) {
      console.error('❌ Coverage heatmap service error:', err);
      setError(`Service Error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };


  const getStatusColor = (status: string) => {
    switch (status) {
      case 'optimal': return 'bg-green-500';
      case 'adequate': return 'bg-yellow-500';
      case 'shortage': return 'bg-red-500';
      case 'surplus': return 'bg-blue-500';
      default: return 'bg-gray-300';
    }
  };

  const getIntensityColor = (intensity: number, status: string) => {
    // Create rgba color based on status and intensity
    switch (status) {
      case 'optimal': return `rgba(34, 197, 94, ${Math.min(1, intensity)})`;
      case 'adequate': return `rgba(234, 179, 8, ${Math.min(1, intensity)})`;
      case 'shortage': return `rgba(239, 68, 68, ${Math.min(1, Math.max(0.3, intensity))})`;
      case 'surplus': return `rgba(59, 130, 246, ${Math.min(1, intensity)})`;
      default: return `rgba(156, 163, 175, ${Math.min(1, intensity)})`;
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 text-red-800 border-red-200';
      case 'high': return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'low': return 'bg-blue-100 text-blue-800 border-blue-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const exportHeatmapData = async () => {
    if (!coverageData) return;
    
    try {
      console.log('[COVERAGE] Exporting heatmap data via service');
      const blob = await realCoverageAnalysisService.exportCoverageReport(selectedServiceId, selectedPeriod, 'csv');
      
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `coverage_heatmap_service_${selectedServiceId}_${selectedPeriod}_${new Date().toISOString().split('T')[0]}.csv`;
      link.click();
    } catch (error) {
      console.error('❌ Export failed:', error);
      
      // Fallback to component-level export
      const csvData = [
        ['День', 'Час', 'Покрытие %', 'Требуется агентов', 'Доступно агентов', 'Уровень сервиса', 'Статус'],
        ...coverageData.heatmap_data.map(item => [
          item.day,
          `${item.hour}:00`,
          item.coverage_percentage.toFixed(1),
          item.agents_required,
          item.agents_available,
          item.service_level.toFixed(1),
          russianTranslations.status[item.status]
        ])
      ];
      
      const csvContent = csvData.map(row => row.join(',')).join('\n');
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `coverage_heatmap_fallback_${new Date().toISOString().split('T')[0]}.csv`;
      link.click();
    }
  };

  const renderHeatmap = () => {
    if (!coverageData) return null;

    const hours = Array.from({ length: 24 }, (_, i) => i);
    
    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900">{russianTranslations.sections.heatmap}</h3>
          <div className="flex items-center gap-4">
            {/* Legend */}
            <div className="flex items-center gap-4 text-sm">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-green-500 rounded"></div>
                <span>{russianTranslations.status.optimal}</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-yellow-500 rounded"></div>
                <span>{russianTranslations.status.adequate}</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-red-500 rounded"></div>
                <span>{russianTranslations.status.shortage}</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-blue-500 rounded"></div>
                <span>{russianTranslations.status.surplus}</span>
              </div>
            </div>
            <button
              onClick={exportHeatmapData}
              className="flex items-center gap-2 px-3 py-1 text-sm text-blue-600 hover:text-blue-800"
            >
              <Download className="h-4 w-4" />
              {russianTranslations.actions.export}
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <div className="grid grid-cols-25 gap-1 min-w-max">
            {/* Header row */}
            <div className="text-xs font-medium text-gray-600 flex items-center justify-center p-2">
              День/Час
            </div>
            {hours.map(hour => (
              <div key={hour} className="text-xs text-gray-600 text-center p-1">
                {String(hour).padStart(2, '0')}:00
              </div>
            ))}
            
            {/* Data rows */}
            {russianTranslations.time.days.map(day => (
              <React.Fragment key={day}>
                <div className="text-sm font-medium text-gray-700 flex items-center justify-center p-2 bg-gray-50">
                  {day}
                </div>
                {hours.map(hour => {
                  const cellData = coverageData.heatmap_data.find(d => d.day === day && d.hour === hour);
                  if (!cellData) return <div key={`${day}-${hour}`} className="aspect-square bg-gray-100 rounded"></div>;
                  
                  return (
                    <div
                      key={`${day}-${hour}`}
                      className="aspect-square rounded cursor-pointer hover:scale-110 transition-transform border border-white relative"
                      style={{
                        backgroundColor: getIntensityColor(cellData.intensity, cellData.status)
                      }}
                      onMouseEnter={() => setHoveredCell(cellData)}
                      onMouseLeave={() => setHoveredCell(null)}
                      title={`${day} ${String(hour).padStart(2, '0')}:00\nПокрытие: ${cellData.coverage_percentage.toFixed(1)}%\nАгенты: ${cellData.agents_available}/${cellData.agents_required}\nСтатус: ${russianTranslations.status[cellData.status]}`}
                    >
                      {cellData.status === 'shortage' && (
                        <AlertTriangle className="h-3 w-3 text-white absolute inset-0 m-auto" />
                      )}
                    </div>
                  );
                })}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Hover tooltip */}
        {hoveredCell && (
          <div className="mt-4 p-4 bg-gray-50 rounded-lg">
            <h4 className="font-medium text-gray-900 mb-2">
              {hoveredCell.day} {String(hoveredCell.hour).padStart(2, '0')}:00
            </h4>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div>
                <span className="text-gray-600">Покрытие:</span>
                <span className="ml-2 font-medium">{hoveredCell.coverage_percentage.toFixed(1)}%</span>
              </div>
              <div>
                <span className="text-gray-600">Агенты:</span>
                <span className="ml-2 font-medium">{hoveredCell.agents_available}/{hoveredCell.agents_required}</span>
              </div>
              <div>
                <span className="text-gray-600">Уровень сервиса:</span>
                <span className="ml-2 font-medium">{hoveredCell.service_level.toFixed(1)}%</span>
              </div>
              <div>
                <span className="text-gray-600">Статус:</span>
                <span className={`ml-2 px-2 py-1 rounded text-xs ${getStatusColor(hoveredCell.status)} text-white`}>
                  {russianTranslations.status[hoveredCell.status]}
                </span>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  };

  const renderStatistics = () => {
    if (!coverageData) return null;

    const criticalGaps = coverageData.coverage_gaps.filter(g => g.severity === 'critical').length;
    
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">{russianTranslations.metrics.avgCoverage}</p>
              <p className="text-2xl font-bold text-blue-600">{coverageData.average_coverage.toFixed(1)}%</p>
            </div>
            <Target className="h-8 w-8 text-blue-600" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">{russianTranslations.metrics.serviceLevelForecast}</p>
              <p className="text-2xl font-bold text-green-600">{coverageData.service_level_forecast.toFixed(1)}%</p>
            </div>
            <Activity className="h-8 w-8 text-green-600" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">{russianTranslations.metrics.criticalGaps}</p>
              <p className="text-2xl font-bold text-red-600">{criticalGaps}</p>
            </div>
            <AlertTriangle className="h-8 w-8 text-red-600" />
          </div>
        </div>
      </div>
    );
  };

  const renderCoverageGaps = () => {
    if (!coverageData || coverageData.coverage_gaps.length === 0) {
      return (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">{russianTranslations.sections.gaps}</h3>
          <div className="text-center py-8 text-gray-500">
            <CheckCircle className="h-12 w-12 mx-auto mb-3 text-green-500" />
            <p>Критических пробелов в покрытии не обнаружено</p>
          </div>
        </div>
      );
    }

    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">{russianTranslations.sections.gaps}</h3>
        <div className="space-y-4">
          {coverageData.coverage_gaps.slice(0, 10).map((gap, index) => (
            <div key={index} className={`p-4 rounded-lg border ${getSeverityColor(gap.severity)}`}>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <AlertTriangle className="h-5 w-5" />
                  <span className="font-medium">
                    {gap.start_time} - {gap.end_time}
                  </span>
                </div>
                <span className="text-sm font-medium">
                  {russianTranslations.severity[gap.severity]}
                </span>
              </div>
              <div className="text-sm mb-3">
                <p>Недостаток агентов: <strong>{gap.agents_short.toFixed(1)}</strong></p>
                <p>Влияние на SL: <strong>-{gap.impact_on_service_level.toFixed(1)}%</strong></p>
              </div>
              <div className="text-sm">
                <p className="font-medium mb-1">Рекомендации:</p>
                <ul className="list-disc list-inside space-y-1">
                  {gap.recommended_actions.map((action, i) => (
                    <li key={i}>{action}</li>
                  ))}
                </ul>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-3"></div>
          <p className="text-gray-600">Загрузка тепловой карты покрытия...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6" data-testid="coverage-heatmap">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{russianTranslations.title}</h1>
          <p className="text-gray-600">{russianTranslations.subtitle}</p>
        </div>
        
        <div className="flex items-center gap-3">
          <select
            value={selectedServiceId}
            onChange={(e) => setSelectedServiceId(Number(e.target.value))}
            className="px-3 py-2 border border-gray-300 rounded-lg bg-white"
          >
            <option value={1}>Служба поддержки</option>
            <option value={2}>Продажи</option>
            <option value={3}>Техподдержка</option>
          </select>
          
          <select
            value={selectedPeriod}
            onChange={(e) => setSelectedPeriod(e.target.value as any)}
            className="px-3 py-2 border border-gray-300 rounded-lg bg-white"
          >
            <option value="7d">7 дней</option>
            <option value="30d">30 дней</option>
            <option value="90d">90 дней</option>
          </select>
          
          <button
            onClick={loadCoverageHeatmap}
            disabled={refreshing}
            className="flex items-center gap-2 px-3 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
            {russianTranslations.actions.refresh}
          </button>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-yellow-800">{error}</p>
        </div>
      )}

      {/* Statistics Overview */}
      {renderStatistics()}

      {/* Heatmap */}
      {renderHeatmap()}

      {/* Coverage Gaps */}  
      {renderCoverageGaps()}
    </div>
  );
};

export default CoverageHeatmap;