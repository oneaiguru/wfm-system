import React, { useState, useEffect } from 'react';
import { BarChart3, TrendingUp, Users, Clock, Target, AlertTriangle, Download, Calendar } from 'lucide-react';
import ForecastChart from './ForecastChart';
import ScenarioSliders from './ScenarioSliders';
import ForecastAccuracy from './ForecastAccuracy';

interface AnalyticsDashboardProps {
  userId: string;
  userRole: 'employee' | 'supervisor' | 'admin';
}

interface DashboardMetrics {
  totalCallVolume: number;
  averageAHT: number;
  serviceLevel: number;
  staffUtilization: number;
  forecastAccuracy: number;
  costPerCall: number;
  customerSatisfaction: number;
  staffTurnover: number;
}

interface TrendData {
  period: string;
  value: number;
  change: number;
  trend: 'up' | 'down' | 'stable';
}

interface AlertData {
  id: string;
  type: 'forecast' | 'performance' | 'staffing' | 'cost';
  severity: 'low' | 'medium' | 'high';
  message: string;
  timestamp: Date;
  acknowledged: boolean;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

// Russian translations
const translations = {
  title: 'Аналитика и прогнозирование',
  subtitle: 'Комплексный анализ производительности контакт-центра',
  tabs: {
    overview: 'Обзор',
    forecasting: 'Прогнозирование',
    scenarios: 'Сценарии',
    accuracy: 'Точность',
    reports: 'Отчеты'
  },
  metrics: {
    totalCallVolume: 'Общий объем звонков',
    averageAHT: 'Среднее время обработки',
    serviceLevel: 'Уровень сервиса',
    staffUtilization: 'Загрузка персонала',
    forecastAccuracy: 'Точность прогноза',
    costPerCall: 'Стоимость звонка',
    customerSatisfaction: 'Удовлетворенность клиентов',
    staffTurnover: 'Текучесть кадров'
  },
  trends: {
    title: 'Тенденции',
    thisWeek: 'На этой неделе',
    lastWeek: 'На прошлой неделе',
    thisMonth: 'В этом месяце',
    lastMonth: 'В прошлом месяце',
    up: 'Рост',
    down: 'Снижение',
    stable: 'Стабильно'
  },
  alerts: {
    title: 'Предупреждения',
    new: 'Новое',
    acknowledged: 'Подтверждено',
    all: 'Все',
    acknowledge: 'Подтвердить',
    markAllRead: 'Отметить все как прочитанные'
  },
  actions: {
    export: 'Экспорт',
    refresh: 'Обновить',
    configure: 'Настроить',
    viewDetails: 'Подробности',
    generateReport: 'Создать отчет'
  },
  reports: {
    title: 'Быстрые отчеты',
    dailyPerformance: 'Дневная производительность',
    weeklyForecast: 'Недельный прогноз',
    monthlyAnalysis: 'Месячный анализ',
    staffingReport: 'Отчет по персоналу',
    costAnalysis: 'Анализ затрат',
    customerMetrics: 'Метрики клиентов'
  },
  noData: 'Нет данных для отображения',
  loading: 'Загрузка аналитики...',
  error: 'Ошибка загрузки данных'
};

const AnalyticsDashboard: React.FC<AnalyticsDashboardProps> = ({ userId, userRole }) => {
  const [activeTab, setActiveTab] = useState<'overview' | 'forecasting' | 'scenarios' | 'accuracy' | 'reports'>('overview');
  const [metrics, setMetrics] = useState<DashboardMetrics>({
    totalCallVolume: 0,
    averageAHT: 0,
    serviceLevel: 0,
    staffUtilization: 0,
    forecastAccuracy: 0,
    costPerCall: 0,
    customerSatisfaction: 0,
    staffTurnover: 0
  });
  const [trends, setTrends] = useState<TrendData[]>([]);
  const [alerts, setAlerts] = useState<AlertData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadAnalyticsData();
  }, [userId, userRole]);

  const loadAnalyticsData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(
        `${API_BASE_URL}/analytics/dashboard?user_id=${userId}&role=${userRole}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`
          }
        }
      );

      if (response.ok) {
        const data = await response.json();
        
        // Set metrics
        setMetrics({
          totalCallVolume: data.metrics?.total_call_volume || 0,
          averageAHT: data.metrics?.average_aht || 0,
          serviceLevel: data.metrics?.service_level || 0,
          staffUtilization: data.metrics?.staff_utilization || 0,
          forecastAccuracy: data.metrics?.forecast_accuracy || 0,
          costPerCall: data.metrics?.cost_per_call || 0,
          customerSatisfaction: data.metrics?.customer_satisfaction || 0,
          staffTurnover: data.metrics?.staff_turnover || 0
        });

        // Set trends
        setTrends((data.trends || []).map((trend: any) => ({
          period: trend.period,
          value: trend.value,
          change: trend.change,
          trend: trend.trend
        })));

        // Set alerts
        setAlerts((data.alerts || []).map((alert: any) => ({
          id: alert.id,
          type: alert.type,
          severity: alert.severity,
          message: alert.message,
          timestamp: new Date(alert.timestamp),
          acknowledged: alert.acknowledged
        })));

      } else {
        throw new Error('Failed to load analytics data');
      }
    } catch (error) {
      console.error('Error loading analytics data:', error);
      setError(translations.error);
    } finally {
      setLoading(false);
    }
  };

  const acknowledgeAlert = async (alertId: string) => {
    try {
      await fetch(`${API_BASE_URL}/analytics/alerts/${alertId}/acknowledge`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        }
      });

      setAlerts(prev => prev.map(alert => 
        alert.id === alertId ? { ...alert, acknowledged: true } : alert
      ));
    } catch (error) {
      console.error('Error acknowledging alert:', error);
    }
  };

  const exportReport = async (reportType: string) => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/analytics/export?type=${reportType}&user_id=${userId}&role=${userRole}`,
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
        a.download = `analytics_${reportType}_${new Date().toISOString().split('T')[0]}.xlsx`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      }
    } catch (error) {
      console.error('Error exporting report:', error);
    }
  };

  const getMetricColor = (value: number, threshold: number, inverse: boolean = false) => {
    const isGood = inverse ? value < threshold : value >= threshold;
    return isGood ? 'text-green-600' : 'text-red-600';
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up':
        return <TrendingUp className="h-4 w-4 text-green-600" />;
      case 'down':
        return <TrendingUp className="h-4 w-4 text-red-600 rotate-180" />;
      default:
        return <BarChart3 className="h-4 w-4 text-gray-600" />;
    }
  };

  const getAlertIcon = (type: string) => {
    switch (type) {
      case 'forecast':
        return <BarChart3 className="h-4 w-4" />;
      case 'performance':
        return <Target className="h-4 w-4" />;
      case 'staffing':
        return <Users className="h-4 w-4" />;
      case 'cost':
        return <AlertTriangle className="h-4 w-4" />;
      default:
        return <AlertTriangle className="h-4 w-4" />;
    }
  };

  const getAlertColor = (severity: string) => {
    switch (severity) {
      case 'high':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'low':
        return 'bg-blue-100 text-blue-800 border-blue-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const renderMetricCard = (
    title: string, 
    value: number, 
    suffix: string = '', 
    icon: React.ReactNode,
    threshold?: number,
    inverse?: boolean
  ) => (
    <div className="bg-white rounded-lg shadow-sm p-4 border border-gray-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <p className={`text-2xl font-bold ${threshold ? getMetricColor(value, threshold, inverse) : 'text-gray-900'}`}>
            {typeof value === 'number' ? value.toLocaleString('ru-RU') : value}{suffix}
          </p>
        </div>
        <div className="p-2 bg-blue-50 rounded-lg">
          {icon}
        </div>
      </div>
    </div>
  );

  const renderOverviewTab = () => (
    <div className="space-y-6">
      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {renderMetricCard(
          translations.metrics.totalCallVolume,
          metrics.totalCallVolume,
          '',
          <BarChart3 className="h-5 w-5 text-blue-600" />
        )}
        {renderMetricCard(
          translations.metrics.serviceLevel,
          metrics.serviceLevel,
          '%',
          <Target className="h-5 w-5 text-blue-600" />,
          80
        )}
        {renderMetricCard(
          translations.metrics.staffUtilization,
          metrics.staffUtilization,
          '%',
          <Users className="h-5 w-5 text-blue-600" />,
          85
        )}
        {renderMetricCard(
          translations.metrics.forecastAccuracy,
          metrics.forecastAccuracy,
          '%',
          <TrendingUp className="h-5 w-5 text-blue-600" />,
          90
        )}
      </div>

      {/* Additional Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {renderMetricCard(
          translations.metrics.averageAHT,
          metrics.averageAHT,
          ' сек',
          <Clock className="h-5 w-5 text-blue-600" />,
          300,
          true
        )}
        {renderMetricCard(
          translations.metrics.costPerCall,
          metrics.costPerCall,
          ' ₽',
          <AlertTriangle className="h-5 w-5 text-blue-600" />
        )}
        {renderMetricCard(
          translations.metrics.customerSatisfaction,
          metrics.customerSatisfaction,
          '%',
          <Target className="h-5 w-5 text-blue-600" />,
          85
        )}
        {renderMetricCard(
          translations.metrics.staffTurnover,
          metrics.staffTurnover,
          '%',
          <Users className="h-5 w-5 text-blue-600" />,
          15,
          true
        )}
      </div>

      {/* Trends and Alerts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Trends */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">{translations.trends.title}</h3>
          </div>
          <div className="p-4">
            {trends.length > 0 ? (
              <div className="space-y-3">
                {trends.map((trend, index) => (
                  <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded">
                    <div className="flex items-center gap-3">
                      {getTrendIcon(trend.trend)}
                      <span className="font-medium text-gray-900">{trend.period}</span>
                    </div>
                    <div className="text-right">
                      <div className="font-bold text-gray-900">{trend.value.toLocaleString('ru-RU')}</div>
                      <div className={`text-sm ${trend.change > 0 ? 'text-green-600' : 'text-red-600'}`}>
                        {trend.change > 0 ? '+' : ''}{trend.change}%
                      </div>
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

        {/* Alerts */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">{translations.alerts.title}</h3>
          </div>
          <div className="p-4">
            {alerts.length > 0 ? (
              <div className="space-y-3">
                {alerts.slice(0, 5).map((alert) => (
                  <div key={alert.id} className={`p-3 rounded border ${getAlertColor(alert.severity)}`}>
                    <div className="flex items-start gap-3">
                      {getAlertIcon(alert.type)}
                      <div className="flex-1">
                        <p className="text-sm font-medium">{alert.message}</p>
                        <p className="text-xs mt-1 opacity-75">
                          {alert.timestamp.toLocaleString('ru-RU')}
                        </p>
                      </div>
                      {!alert.acknowledged && (
                        <button
                          onClick={() => acknowledgeAlert(alert.id)}
                          className="text-xs px-2 py-1 bg-white rounded hover:bg-gray-50"
                        >
                          {translations.alerts.acknowledge}
                        </button>
                      )}
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
      </div>
    </div>
  );

  const renderReportsTab = () => (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">{translations.reports.title}</h3>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {Object.entries(translations.reports).filter(([key]) => key !== 'title').map(([key, label]) => (
              <button
                key={key}
                onClick={() => exportReport(key)}
                className="p-4 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors text-center"
              >
                <Download className="h-6 w-6 text-blue-600 mx-auto mb-2" />
                <span className="text-sm font-medium text-blue-900">{label}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderTabContent = () => {
    switch (activeTab) {
      case 'overview':
        return renderOverviewTab();
      case 'forecasting':
        return <ForecastChart />;
      case 'scenarios':
        return <ScenarioSliders />;
      case 'accuracy':
        return <ForecastAccuracy />;
      case 'reports':
        return renderReportsTab();
      default:
        return renderOverviewTab();
    }
  };

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-300 rounded w-1/3"></div>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="h-24 bg-gray-300 rounded"></div>
            ))}
          </div>
          <div className="h-64 bg-gray-300 rounded"></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="text-center py-12">
            <AlertTriangle className="h-12 w-12 text-red-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">{translations.error}</h3>
            <p className="text-gray-500 mb-4">{error}</p>
            <button
              onClick={loadAnalyticsData}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              {translations.actions.refresh}
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6" data-testid="analytics-dashboard">
      <div className="bg-white rounded-lg shadow-sm">
        {/* Header */}
        <div className="border-b border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <BarChart3 className="h-6 w-6 text-blue-600" />
              <div>
                <h2 className="text-2xl font-semibold text-gray-900">{translations.title}</h2>
                <p className="text-gray-600">{translations.subtitle}</p>
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              <button
                onClick={loadAnalyticsData}
                className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
                title={translations.actions.refresh}
              >
                <Calendar className="h-5 w-5" />
              </button>
            </div>
          </div>

          {/* Tabs */}
          <div className="mt-6 flex gap-1 bg-gray-100 rounded-lg p-1">
            {Object.entries(translations.tabs).map(([key, label]) => (
              <button
                key={key}
                onClick={() => setActiveTab(key as any)}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors flex-1 ${
                  activeTab === key
                    ? 'bg-white text-blue-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Tab Content */}
        <div className="p-6">
          {renderTabContent()}
        </div>
      </div>
    </div>
  );
};

export default AnalyticsDashboard;