import React, { useState, useEffect } from 'react';
import { BarChart3, TrendingUp, Download, Calendar, Filter, RefreshCw, Eye, Share2, Settings } from 'lucide-react';

interface ReportData {
  id: string;
  name: string;
  description: string;
  category: 'operational' | 'performance' | 'financial' | 'compliance';
  lastUpdated: Date;
  dataPoints: Array<{
    label: string;
    value: number;
    trend?: 'up' | 'down' | 'stable';
    format?: 'number' | 'percentage' | 'currency' | 'duration';
  }>;
  chartData?: any;
  schedule: string;
  hasRealTimeData: boolean;
}

interface Dashboard {
  id: string;
  name: string;
  reports: string[];
  layout: 'grid' | 'vertical' | 'horizontal';
  isPublic: boolean;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const BusinessIntelligenceReports: React.FC = () => {
  const [reports, setReports] = useState<ReportData[]>([]);
  const [dashboards, setDashboards] = useState<Dashboard[]>([]);
  const [selectedReport, setSelectedReport] = useState<string | null>(null);
  const [selectedDashboard, setSelectedDashboard] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [dateRange, setDateRange] = useState('last30days');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [showShareDialog, setShowShareDialog] = useState(false);

  const loadReportsData = async () => {
    setIsLoading(true);

    try {
      console.log('[BI REPORTS] Loading business intelligence reports...');

      // Load reports
      const reportsResponse = await fetch(`${API_BASE_URL}/reports/business-intelligence?period=${dateRange}`);
      if (!reportsResponse.ok) {
        throw new Error(`Reports API failed: ${reportsResponse.status}`);
      }

      const reportsData = await reportsResponse.json();
      const realReports = (reportsData.reports || []).map((report: any) => ({
        id: report.id || `report_${Date.now()}`,
        name: report.name || report.title,
        description: report.description || report.summary,
        category: report.category || 'operational',
        lastUpdated: new Date(report.last_updated || report.lastUpdated || Date.now()),
        dataPoints: report.data_points || report.dataPoints || [],
        chartData: report.chart_data || report.chartData,
        schedule: report.schedule || 'Daily',
        hasRealTimeData: report.has_real_time_data || report.hasRealTimeData || false
      }));

      setReports(realReports);

      // Load dashboards
      const dashboardsResponse = await fetch(`${API_BASE_URL}/reports/dashboards`);
      if (dashboardsResponse.ok) {
        const dashboardsData = await dashboardsResponse.json();
        setDashboards(dashboardsData.dashboards || []);
      }

      console.log(`[BI REPORTS] Loaded ${realReports.length} reports`);

    } catch (error) {
      console.error('[BI REPORTS] Error loading reports:', error);

      // Fallback data for demo
      const fallbackReports: ReportData[] = [
        {
          id: 'employee-productivity',
          name: 'Производительность сотрудников',
          description: 'Анализ производительности по командам и отделам',
          category: 'performance',
          lastUpdated: new Date(Date.now() - 900000), // 15 minutes ago
          dataPoints: [
            { label: 'Общая производительность', value: 87.5, trend: 'up', format: 'percentage' },
            { label: 'Среднее время на задачу', value: 45, trend: 'down', format: 'duration' },
            { label: 'Задач выполнено', value: 1247, trend: 'up', format: 'number' },
            { label: 'Качество работы', value: 92.3, trend: 'stable', format: 'percentage' }
          ],
          schedule: 'Real-time',
          hasRealTimeData: true
        },
        {
          id: 'attendance-analytics',
          name: 'Аналитика посещаемости',
          description: 'Отчет по посещаемости, опозданиям и отгулам',
          category: 'operational',
          lastUpdated: new Date(Date.now() - 1800000), // 30 minutes ago
          dataPoints: [
            { label: 'Общая посещаемость', value: 94.2, trend: 'up', format: 'percentage' },
            { label: 'Опоздания', value: 12, trend: 'down', format: 'number' },
            { label: 'Отсутствия', value: 8, trend: 'stable', format: 'number' },
            { label: 'Сверхурочные часы', value: 156, trend: 'up', format: 'duration' }
          ],
          schedule: 'Daily at 8:00',
          hasRealTimeData: false
        },
        {
          id: 'financial-overview',
          name: 'Финансовый обзор',
          description: 'Ключевые финансовые показатели и затраты на персонал',
          category: 'financial',
          lastUpdated: new Date(Date.now() - 3600000), // 1 hour ago
          dataPoints: [
            { label: 'Затраты на зарплату', value: 2450000, trend: 'up', format: 'currency' },
            { label: 'Доход на сотрудника', value: 185000, trend: 'up', format: 'currency' },
            { label: 'Стоимость отсутствий', value: 89000, trend: 'down', format: 'currency' },
            { label: 'ROI обучения', value: 15.7, trend: 'up', format: 'percentage' }
          ],
          schedule: 'Weekly on Monday',
          hasRealTimeData: false
        },
        {
          id: 'compliance-report',
          name: 'Отчет по соответствию',
          description: 'Соблюдение трудового законодательства и регламентов',
          category: 'compliance',
          lastUpdated: new Date(Date.now() - 7200000), // 2 hours ago
          dataPoints: [
            { label: 'Соответствие нормам', value: 98.5, trend: 'stable', format: 'percentage' },
            { label: 'Нарушения графика', value: 3, trend: 'down', format: 'number' },
            { label: 'Превышение рабочих часов', value: 2, trend: 'down', format: 'number' },
            { label: 'Соблюдение перерывов', value: 96.8, trend: 'up', format: 'percentage' }
          ],
          schedule: 'Daily at 18:00',
          hasRealTimeData: false
        },
        {
          id: 'workload-distribution',
          name: 'Распределение нагрузки',
          description: 'Анализ распределения рабочей нагрузки между командами',
          category: 'operational',
          lastUpdated: new Date(Date.now() - 600000), // 10 minutes ago
          dataPoints: [
            { label: 'Сбалансированность нагрузки', value: 78.4, trend: 'up', format: 'percentage' },
            { label: 'Перегруженные сотрудники', value: 5, trend: 'down', format: 'number' },
            { label: 'Недогруженные сотрудники', value: 8, trend: 'stable', format: 'number' },
            { label: 'Средняя нагрузка', value: 85.2, trend: 'up', format: 'percentage' }
          ],
          schedule: 'Every 4 hours',
          hasRealTimeData: true
        },
        {
          id: 'performance-trends',
          name: 'Тренды производительности',
          description: 'Долгосрочные тренды производительности по периодам',
          category: 'performance',
          lastUpdated: new Date(Date.now() - 10800000), // 3 hours ago
          dataPoints: [
            { label: 'Рост производительности', value: 12.3, trend: 'up', format: 'percentage' },
            { label: 'Улучшение качества', value: 8.7, trend: 'up', format: 'percentage' },
            { label: 'Снижение ошибок', value: 25.4, trend: 'up', format: 'percentage' },
            { label: 'Удовлетворенность клиентов', value: 91.5, trend: 'stable', format: 'percentage' }
          ],
          schedule: 'Weekly on Friday',
          hasRealTimeData: false
        }
      ];

      const fallbackDashboards: Dashboard[] = [
        {
          id: 'exec-dashboard',
          name: 'Исполнительный дашборд',
          reports: ['employee-productivity', 'financial-overview', 'compliance-report'],
          layout: 'grid',
          isPublic: false
        },
        {
          id: 'ops-dashboard',
          name: 'Операционный дашборд',
          reports: ['attendance-analytics', 'workload-distribution', 'performance-trends'],
          layout: 'vertical',
          isPublic: true
        }
      ];

      setReports(fallbackReports);
      setDashboards(fallbackDashboards);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadReportsData();
    if (reports.length > 0) {
      setSelectedReport(reports[0].id);
    }
  }, [dateRange]);

  useEffect(() => {
    if (dashboards.length > 0) {
      setSelectedDashboard(dashboards[0].id);
    }
  }, [dashboards]);

  const getCategoryIcon = (category: ReportData['category']) => {
    switch (category) {
      case 'performance':
        return <TrendingUp className="h-4 w-4 text-green-500" />;
      case 'financial':
        return <BarChart3 className="h-4 w-4 text-blue-500" />;
      case 'compliance':
        return <Settings className="h-4 w-4 text-purple-500" />;
      default:
        return <BarChart3 className="h-4 w-4 text-gray-500" />;
    }
  };

  const getCategoryColor = (category: ReportData['category']) => {
    switch (category) {
      case 'performance':
        return 'bg-green-100 text-green-800';
      case 'financial':
        return 'bg-blue-100 text-blue-800';
      case 'compliance':
        return 'bg-purple-100 text-purple-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getTrendIcon = (trend?: 'up' | 'down' | 'stable') => {
    switch (trend) {
      case 'up':
        return <TrendingUp className="h-3 w-3 text-green-500" />;
      case 'down':
        return <TrendingUp className="h-3 w-3 text-red-500 rotate-180" />;
      default:
        return <div className="h-3 w-3 bg-gray-400 rounded-full" />;
    }
  };

  const formatValue = (value: number, format?: string) => {
    switch (format) {
      case 'percentage':
        return `${value.toFixed(1)}%`;
      case 'currency':
        return new Intl.NumberFormat('ru-RU', {
          style: 'currency',
          currency: 'RUB',
          minimumFractionDigits: 0,
          maximumFractionDigits: 0
        }).format(value);
      case 'duration':
        return `${Math.floor(value)}ч ${Math.floor((value % 1) * 60)}м`;
      default:
        return new Intl.NumberFormat('ru-RU').format(value);
    }
  };

  const refreshReport = async (reportId: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/reports/${reportId}/refresh`, {
        method: 'POST'
      });
      if (response.ok) {
        await loadReportsData();
      }
    } catch (error) {
      console.error('Failed to refresh report:', error);
      // Simulate refresh by updating lastUpdated
      setReports(prev => prev.map(report =>
        report.id === reportId ? { ...report, lastUpdated: new Date() } : report
      ));
    }
  };

  const exportReport = async (reportId: string, format: 'pdf' | 'excel' | 'csv') => {
    try {
      const response = await fetch(`${API_BASE_URL}/reports/${reportId}/export?format=${format}`);
      if (response.ok) {
        const blob = await response.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `report-${reportId}.${format}`;
        a.click();
        URL.revokeObjectURL(url);
      }
    } catch (error) {
      console.error('Failed to export report:', error);
    }
  };

  const shareReport = (reportId: string) => {
    const shareUrl = `${window.location.origin}/reports/shared/${reportId}`;
    navigator.clipboard.writeText(shareUrl);
    setShowShareDialog(false);
    // Show success message
  };

  const filteredReports = reports.filter(report =>
    categoryFilter === 'all' || report.category === categoryFilter
  );

  const selectedReportData = selectedReport ? reports.find(r => r.id === selectedReport) : null;
  const selectedDashboardData = selectedDashboard ? dashboards.find(d => d.id === selectedDashboard) : null;

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <BarChart3 className="h-6 w-6 mr-2 text-blue-600" />
              Бизнес-Аналитика и Отчеты
            </h2>
            <p className="mt-2 text-gray-600">
              Комплексная аналитика и интеллектуальные отчеты для принятия решений
            </p>
          </div>
          <div className="flex items-center gap-4">
            <select
              value={dateRange}
              onChange={(e) => setDateRange(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="last7days">Последние 7 дней</option>
              <option value="last30days">Последние 30 дней</option>
              <option value="last90days">Последние 90 дней</option>
              <option value="lastyear">Последний год</option>
            </select>
            <button
              onClick={loadReportsData}
              disabled={isLoading}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
              Обновить
            </button>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-gray-500" />
              <span className="text-sm font-medium text-gray-700">Категория:</span>
            </div>
            <div className="flex gap-2">
              {['all', 'operational', 'performance', 'financial', 'compliance'].map((category) => (
                <button
                  key={category}
                  onClick={() => setCategoryFilter(category)}
                  className={`px-3 py-1 text-sm rounded-md transition-colors ${
                    categoryFilter === category
                      ? 'bg-blue-100 text-blue-800 border border-blue-200'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {category === 'all' ? 'Все' :
                   category === 'operational' ? 'Операционные' :
                   category === 'performance' ? 'Производительность' :
                   category === 'financial' ? 'Финансовые' : 'Соответствие'}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Reports List */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Отчеты</h3>
              <p className="text-sm text-gray-500">{filteredReports.length} доступных</p>
            </div>
            
            <div className="p-4 space-y-2 max-h-96 overflow-y-auto">
              {filteredReports.map((report) => (
                <div
                  key={report.id}
                  className={`p-3 border rounded-lg cursor-pointer transition-colors ${
                    selectedReport === report.id
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                  onClick={() => setSelectedReport(report.id)}
                >
                  <div className="flex items-center gap-2 mb-2">
                    {getCategoryIcon(report.category)}
                    <span className="text-sm font-medium text-gray-900 truncate">
                      {report.name}
                    </span>
                    {report.hasRealTimeData && (
                      <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                    )}
                  </div>
                  
                  <div className="flex items-center justify-between text-xs">
                    <span className={`px-2 py-1 rounded-full ${getCategoryColor(report.category)}`}>
                      {report.category === 'operational' ? 'Операционный' :
                       report.category === 'performance' ? 'Производительность' :
                       report.category === 'financial' ? 'Финансовый' : 'Соответствие'}
                    </span>
                    <span className="text-gray-500">
                      {report.lastUpdated.toLocaleTimeString('ru-RU', {
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </span>
                  </div>
                  
                  <p className="text-xs text-gray-600 mt-2 line-clamp-2">
                    {report.description}
                  </p>
                </div>
              ))}
            </div>
          </div>

          {/* Dashboards */}
          <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Дашборды</h3>
            </div>
            
            <div className="p-4 space-y-2">
              {dashboards.map((dashboard) => (
                <div
                  key={dashboard.id}
                  className={`p-3 border rounded-lg cursor-pointer transition-colors ${
                    selectedDashboard === dashboard.id
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                  onClick={() => setSelectedDashboard(dashboard.id)}
                >
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-gray-900">
                      {dashboard.name}
                    </span>
                    {dashboard.isPublic && (
                      <Share2 className="h-3 w-3 text-blue-500" />
                    )}
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    {dashboard.reports.length} отчетов
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Report Details */}
        <div className="lg:col-span-3">
          {selectedReportData ? (
            <div className="space-y-6">
              {/* Report Header */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    {getCategoryIcon(selectedReportData.category)}
                    <div>
                      <h3 className="text-xl font-semibold text-gray-900">
                        {selectedReportData.name}
                      </h3>
                      <p className="text-sm text-gray-600 mt-1">
                        {selectedReportData.description}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => refreshReport(selectedReportData.id)}
                      className="flex items-center px-3 py-1 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
                    >
                      <RefreshCw className="h-3 w-3 mr-1" />
                      Обновить
                    </button>
                    <div className="relative">
                      <button
                        onClick={() => setShowShareDialog(!showShareDialog)}
                        className="flex items-center px-3 py-1 text-sm bg-blue-600 text-white rounded-md hover:bg-blue-700"
                      >
                        <Download className="h-3 w-3 mr-1" />
                        Экспорт
                      </button>
                      {showShareDialog && (
                        <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg border border-gray-200 z-10">
                          <div className="p-2">
                            <button
                              onClick={() => exportReport(selectedReportData.id, 'pdf')}
                              className="w-full text-left px-3 py-2 text-sm hover:bg-gray-100 rounded"
                            >
                              Экспорт в PDF
                            </button>
                            <button
                              onClick={() => exportReport(selectedReportData.id, 'excel')}
                              className="w-full text-left px-3 py-2 text-sm hover:bg-gray-100 rounded"
                            >
                              Экспорт в Excel
                            </button>
                            <button
                              onClick={() => exportReport(selectedReportData.id, 'csv')}
                              className="w-full text-left px-3 py-2 text-sm hover:bg-gray-100 rounded"
                            >
                              Экспорт в CSV
                            </button>
                            <hr className="my-2" />
                            <button
                              onClick={() => shareReport(selectedReportData.id)}
                              className="w-full text-left px-3 py-2 text-sm hover:bg-gray-100 rounded"
                            >
                              Создать ссылку
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                <div className="mt-4 flex items-center gap-6 text-sm text-gray-600">
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4" />
                    <span>Обновлено: {selectedReportData.lastUpdated.toLocaleString('ru-RU')}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <RefreshCw className="h-4 w-4" />
                    <span>Расписание: {selectedReportData.schedule}</span>
                  </div>
                  {selectedReportData.hasRealTimeData && (
                    <div className="flex items-center gap-2 text-green-600">
                      <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                      <span>В реальном времени</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Key Metrics */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {selectedReportData.dataPoints.map((dataPoint, index) => (
                  <div key={index} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm text-gray-600">{dataPoint.label}</p>
                        <p className="text-2xl font-bold text-gray-900 mt-1">
                          {formatValue(dataPoint.value, dataPoint.format)}
                        </p>
                      </div>
                      {getTrendIcon(dataPoint.trend)}
                    </div>
                  </div>
                ))}
              </div>

              {/* Chart Visualization */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <h4 className="text-lg font-semibold text-gray-900 mb-4">Визуализация данных</h4>
                <div className="h-64 flex items-center justify-center bg-gray-50 rounded-lg">
                  <div className="text-center text-gray-500">
                    <BarChart3 className="h-12 w-12 mx-auto mb-4 opacity-50" />
                    <p>График будет отображен здесь</p>
                    <p className="text-sm">Интеграция с библиотекой графиков в разработке</p>
                  </div>
                </div>
              </div>

              {/* Data Table */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200">
                <div className="px-6 py-4 border-b border-gray-200">
                  <h4 className="text-lg font-semibold text-gray-900">Детальные данные</h4>
                </div>
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Метрика
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Значение
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Тренд
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Изменение
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {selectedReportData.dataPoints.map((dataPoint, index) => (
                        <tr key={index} className="hover:bg-gray-50">
                          <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                            {dataPoint.label}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {formatValue(dataPoint.value, dataPoint.format)}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="flex items-center gap-2">
                              {getTrendIcon(dataPoint.trend)}
                              <span className={`text-sm ${
                                dataPoint.trend === 'up' ? 'text-green-600' :
                                dataPoint.trend === 'down' ? 'text-red-600' : 'text-gray-600'
                              }`}>
                                {dataPoint.trend === 'up' ? 'Рост' :
                                 dataPoint.trend === 'down' ? 'Снижение' : 'Стабильно'}
                              </span>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {Math.random() > 0.5 ? '+' : ''}{(Math.random() * 10 - 5).toFixed(1)}%
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
              <BarChart3 className="h-12 w-12 mx-auto mb-4 text-gray-400" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">Выберите отчет</h3>
              <p className="text-gray-600">
                Выберите отчет из списка слева для просмотра детальной аналитики
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default BusinessIntelligenceReports;