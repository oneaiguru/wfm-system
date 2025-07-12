import React, { useState, useEffect } from 'react';

// BDD: Database administration dashboard - Adapted from ReportsDashboard
// Based on: 18-system-administration-configuration.feature

interface DatabaseMetric {
  id: string;
  name: string;
  value: number;
  target?: number;
  unit: string;
  status: 'excellent' | 'good' | 'warning' | 'critical';
  trend: 'up' | 'down' | 'stable';
  changePercent: number;
  lastUpdated: Date;
}

interface DatabaseMetricProps {
  metric: DatabaseMetric;
}

const DatabaseMetricCard: React.FC<DatabaseMetricProps> = ({ metric }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return '#10b981';
      case 'good': return '#3b82f6';
      case 'warning': return '#f59e0b';
      case 'critical': return '#ef4444';
      default: return '#6b7280';
    }
  };

  const formatValue = (value: number, unit: string) => {
    if (unit === '%') return `${value.toFixed(1)}%`;
    if (unit === 'ms') return `${value.toFixed(0)}ms`;
    if (unit === 'MB') return `${value.toFixed(0)}MB`;
    if (unit === 'GB') return `${value.toFixed(1)}GB`;
    if (unit === 'connections') return value.toString();
    return value.toFixed(1);
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return '↗';
      case 'down': return '↘';
      case 'stable': return '→';
      default: return '→';
    }
  };

  const getTrendColor = (trend: string) => {
    switch (trend) {
      case 'up': return 'text-green-600';
      case 'down': return 'text-red-600';
      case 'stable': return 'text-gray-600';
      default: return 'text-gray-600';
    }
  };

  const progressPercentage = metric.target ? Math.min((metric.value / metric.target) * 100, 100) : 0;

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600">{metric.name}</p>
          <div className="mt-1 flex items-baseline">
            <p className="text-2xl font-semibold text-gray-900">
              {formatValue(metric.value, metric.unit)}
            </p>
            {metric.target && (
              <p className="ml-2 text-sm text-gray-500">
                / {formatValue(metric.target, metric.unit)}
              </p>
            )}
          </div>
        </div>
        
        <div className="flex flex-col items-end">
          <div 
            className="w-3 h-3 rounded-full mb-2"
            style={{ backgroundColor: getStatusColor(metric.status) }}
          ></div>
          <div className={`flex items-center ${getTrendColor(metric.trend)}`}>
            <span className="text-lg mr-1">{getTrendIcon(metric.trend)}</span>
            <span className="text-sm font-medium">
              {Math.abs(metric.changePercent).toFixed(1)}%
            </span>
          </div>
        </div>
      </div>
      
      {metric.target && (
        <div className="mt-4">
          <div className="flex items-center justify-between text-xs text-gray-500 mb-1">
            <span>Прогресс к цели</span>
            <span>{progressPercentage.toFixed(0)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-1.5">
            <div 
              className="h-1.5 rounded-full transition-all duration-300"
              style={{ 
                width: `${progressPercentage}%`,
                backgroundColor: getStatusColor(metric.status)
              }}
            ></div>
          </div>
        </div>
      )}
      
      <div className="mt-3 text-xs text-gray-400">
        Обновлено: {metric.lastUpdated.toLocaleTimeString('ru-RU')}
      </div>
    </div>
  );
};

const DatabaseAdminDashboard: React.FC = () => {
  const [metrics, setMetrics] = useState<DatabaseMetric[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastRefresh, setLastRefresh] = useState(new Date());

  // BDD: PostgreSQL configuration interface with monitoring
  useEffect(() => {
    const loadDatabaseMetrics = () => {
      const now = new Date();
      const mockMetrics: DatabaseMetric[] = [
        {
          id: '1',
          name: 'Активные подключения',
          value: 47,
          target: 100,
          unit: 'connections',
          status: 'good',
          trend: 'stable',
          changePercent: 0.8,
          lastUpdated: now
        },
        {
          id: '2',
          name: 'Использование CPU',
          value: 23.4,
          target: 80.0,
          unit: '%',
          status: 'excellent',
          trend: 'down',
          changePercent: -2.1,
          lastUpdated: now
        },
        {
          id: '3',
          name: 'Использование памяти',
          value: 67.8,
          target: 85.0,
          unit: '%',
          status: 'good',
          trend: 'up',
          changePercent: 1.5,
          lastUpdated: now
        },
        {
          id: '4',
          name: 'Время ответа запросов',
          value: 45,
          target: 100,
          unit: 'ms',
          status: 'excellent',
          trend: 'down',
          changePercent: -12.3,
          lastUpdated: now
        },
        {
          id: '5',
          name: 'Размер базы данных',
          value: 2.3,
          unit: 'GB',
          status: 'good',
          trend: 'up',
          changePercent: 5.2,
          lastUpdated: now
        },
        {
          id: '6',
          name: 'Успешность резервного копирования',
          value: 98.7,
          target: 95.0,
          unit: '%',
          status: 'excellent',
          trend: 'stable',
          changePercent: 0.3,
          lastUpdated: now
        }
      ];
      
      setMetrics(mockMetrics);
      setLoading(false);
      setLastRefresh(now);
    };

    loadDatabaseMetrics();
    
    // Real-time updates every 30 seconds
    const interval = setInterval(() => {
      loadDatabaseMetrics();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const getOverallDatabaseStatus = () => {
    const excellentCount = metrics.filter(m => m.status === 'excellent').length;
    const goodCount = metrics.filter(m => m.status === 'good').length;
    const total = metrics.length;
    
    if (excellentCount >= total * 0.7) return { status: 'excellent', text: 'База данных работает отлично' };
    if ((excellentCount + goodCount) >= total * 0.8) return { status: 'good', text: 'База данных работает хорошо' };
    return { status: 'warning', text: 'Требует внимания' };
  };

  const overallStatus = getOverallDatabaseStatus();

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return '#10b981';
      case 'good': return '#3b82f6';
      case 'warning': return '#f59e0b';
      case 'critical': return '#ef4444';
      default: return '#6b7280';
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-300 rounded w-1/3 mb-4"></div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="h-32 bg-gray-300 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header - BDD: Database administration monitoring */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Администрирование базы данных</h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">🗄️</span>
              PostgreSQL 15.4 - ООО "ТехноСервис"
            </p>
          </div>
          
          <div className="text-right">
            <div className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
              overallStatus.status === 'excellent' ? 'bg-green-100 text-green-800' :
              overallStatus.status === 'good' ? 'bg-blue-100 text-blue-800' :
              'bg-yellow-100 text-yellow-800'
            }`}>
              <div 
                className="w-2 h-2 rounded-full mr-2"
                style={{ backgroundColor: getStatusColor(overallStatus.status) }}
              ></div>
              {overallStatus.text}
            </div>
            <p className="text-sm text-gray-500 mt-1">
              Общий статус системы
            </p>
            <p className="text-xs text-gray-400 mt-1">
              Последнее обновление: {lastRefresh.toLocaleTimeString('ru-RU')}
            </p>
          </div>
        </div>
      </div>

      {/* Database Metrics Grid - BDD: Performance monitoring */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {metrics.map((metric) => (
          <DatabaseMetricCard key={metric.id} metric={metric} />
        ))}
      </div>

      {/* Quick Insights - BDD: Health monitoring */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Состояние системы</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="font-medium text-gray-900 mb-2 flex items-center">
              <span className="text-lg mr-2">✅</span>
              Работает корректно
            </h4>
            <ul className="text-sm text-gray-600 space-y-1">
              <li>• Время ответа запросов оптимальное</li>
              <li>• Резервное копирование выполняется успешно</li>
              <li>• Использование ресурсов в пределах нормы</li>
              <li>• Подключения стабильны</li>
            </ul>
          </div>
          <div>
            <h4 className="font-medium text-gray-900 mb-2 flex items-center">
              <span className="text-lg mr-2">⚠️</span>
              Требует внимания
            </h4>
            <ul className="text-sm text-gray-600 space-y-1">
              <li>• Мониторить рост базы данных</li>
              <li>• Оптимизировать индексы для ускорения</li>
              <li>• Проверить настройки пула соединений</li>
              <li>• Планировать архивирование старых данных</li>
            </ul>
          </div>
        </div>
      </div>

      {/* Database Connection Info - BDD: Connection monitoring */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Информация о подключении</h3>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Хост:</span>
              <span className="font-medium">localhost:5432</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">База данных:</span>
              <span className="font-medium">wfm_technoservice</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Пользователь:</span>
              <span className="font-medium">wfm_admin</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Макс. подключений:</span>
              <span className="font-medium">100</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Версия:</span>
              <span className="font-medium">PostgreSQL 15.4</span>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Последнее резервное копирование</h3>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Дата:</span>
              <span className="font-medium">15.07.2024 03:00</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Размер:</span>
              <span className="font-medium">1.8 GB</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Статус:</span>
              <span className="text-green-600 font-medium">✓ Успешно</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Длительность:</span>
              <span className="font-medium">12 мин 34 сек</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Следующее:</span>
              <span className="font-medium">16.07.2024 03:00</span>
            </div>
          </div>
        </div>
      </div>

      {/* Real-time Status Bar - BDD: Live monitoring */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
              <span className="text-sm text-gray-600">Данные в реальном времени</span>
            </div>
            <div className="text-sm text-gray-500">
              Обновление каждые 30 секунд
            </div>
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            <span>🟢 {metrics.filter(m => m.status === 'excellent').length} Отлично</span>
            <span>🔵 {metrics.filter(m => m.status === 'good').length} Хорошо</span>
            <span>🟡 {metrics.filter(m => m.status === 'warning').length} Внимание</span>
            <span>🔴 {metrics.filter(m => m.status === 'critical').length} Критично</span>
          </div>
        </div>
      </div>

      {/* Admin Actions - BDD: Database administration interface */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Административные действия</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="flex items-center justify-center px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
            <span className="mr-2">💾</span>
            Создать резервную копию
          </button>
          <button className="flex items-center justify-center px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors">
            <span className="mr-2">🔧</span>
            Оптимизировать индексы
          </button>
          <button className="flex items-center justify-center px-4 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors">
            <span className="mr-2">📊</span>
            Анализ производительности
          </button>
        </div>
      </div>
    </div>
  );
};

export default DatabaseAdminDashboard;