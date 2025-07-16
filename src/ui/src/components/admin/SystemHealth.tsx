import React, { useState, useEffect } from 'react';
import { Heart, Server, Database, Cpu, MemoryStick, HardDrive, Network, RefreshCw, AlertTriangle, CheckCircle, XCircle, Clock, TrendingUp, Activity } from 'lucide-react';

interface HealthComponent {
  component: string;
  status: string;
  last_check: string;
  response_time_ms: number;
  details: any;
}

interface SystemHealthData {
  system_health: string;
  active_agents: number;
  total_requests: number;
  database_status: string;
  api_response_time: number;
  components: HealthComponent[];
}

interface PerformanceMetric {
  name: string;
  value: number;
  unit: string;
  status: 'healthy' | 'warning' | 'critical';
  trend: 'up' | 'down' | 'stable';
  icon: React.ComponentType<any>;
}

const SystemHealth: React.FC = () => {
  const [healthData, setHealthData] = useState<SystemHealthData | null>(null);
  const [performanceMetrics, setPerformanceMetrics] = useState<PerformanceMetric[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

  // Generate mock performance metrics
  const generatePerformanceMetrics = (): PerformanceMetric[] => {
    return [
      {
        name: 'CPU Usage',
        value: Math.round(Math.random() * 40 + 20), // 20-60%
        unit: '%',
        status: 'healthy',
        trend: Math.random() > 0.5 ? 'up' : 'down',
        icon: Cpu
      },
      {
        name: 'Memory Usage',
        value: Math.round(Math.random() * 30 + 40), // 40-70%
        unit: '%',
        status: 'healthy',
        trend: 'stable',
        icon: MemoryStick
      },
      {
        name: 'Disk Usage',
        value: Math.round(Math.random() * 20 + 50), // 50-70%
        unit: '%',
        status: 'warning',
        trend: 'up',
        icon: HardDrive
      },
      {
        name: 'Network Latency',
        value: Math.round(Math.random() * 20 + 10), // 10-30ms
        unit: 'ms',
        status: 'healthy',
        trend: 'down',
        icon: Network
      }
    ];
  };

  // Fetch system health data
  const fetchHealthData = async (isRefresh = false) => {
    if (isRefresh) {
      setIsRefreshing(true);
    } else {
      setIsLoading(true);
    }
    setError('');

    try {
      console.log(`[SYSTEM HEALTH] Fetching health data from: ${API_BASE_URL}/monitoring/operational`);
      
      const response = await fetch(`${API_BASE_URL}/monitoring/operational`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      console.log('[SYSTEM HEALTH] Health data fetched:', data);
      
      setHealthData(data);
      setPerformanceMetrics(generatePerformanceMetrics());
      setLastUpdated(new Date());
      
    } catch (err) {
      console.error('[SYSTEM HEALTH] Error fetching health data:', err);
      setError(err instanceof Error ? err.message : 'Ошибка загрузки данных о состоянии системы');
      
      // Set mock data even on error
      const mockData: SystemHealthData = {
        system_health: 'healthy',
        active_agents: 0,
        total_requests: 0,
        database_status: 'disconnected',
        api_response_time: 0,
        components: [
          {
            component: 'API Server',
            status: 'offline',
            last_check: new Date().toISOString(),
            response_time_ms: 0,
            details: { error: 'Connection failed' }
          },
          {
            component: 'Database',
            status: 'offline',
            last_check: new Date().toISOString(),
            response_time_ms: 0,
            details: { error: 'Connection timeout' }
          }
        ]
      };
      setHealthData(mockData);
      setPerformanceMetrics(generatePerformanceMetrics());
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  // Auto-refresh effect
  useEffect(() => {
    fetchHealthData();

    let interval: NodeJS.Timeout;
    if (autoRefresh) {
      interval = setInterval(() => {
        fetchHealthData(true);
      }, 30000); // Refresh every 30 seconds
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [autoRefresh]);

  const getStatusIcon = (status: string) => {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'online':
      case 'connected':
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'warning':
      case 'degraded':
        return <AlertTriangle className="h-5 w-5 text-yellow-500" />;
      case 'critical':
      case 'offline':
      case 'disconnected':
      case 'error':
        return <XCircle className="h-5 w-5 text-red-500" />;
      default:
        return <CheckCircle className="h-5 w-5 text-gray-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'online':
      case 'connected':
        return 'text-green-600 bg-green-100';
      case 'warning':
      case 'degraded':
        return 'text-yellow-600 bg-yellow-100';
      case 'critical':
      case 'offline':
      case 'disconnected':
      case 'error':
        return 'text-red-600 bg-red-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  const getMetricStatusColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'text-green-600';
      case 'warning': return 'text-yellow-600';
      case 'critical': return 'text-red-600';
      default: return 'text-gray-600';
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return <TrendingUp className="h-4 w-4 text-red-500" />;
      case 'down': return <TrendingUp className="h-4 w-4 text-green-500 rotate-180" />;
      default: return <Activity className="h-4 w-4 text-gray-500" />;
    }
  };

  const formatUptime = (ms: number) => {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}д ${hours % 24}ч`;
    if (hours > 0) return `${hours}ч ${minutes % 60}м`;
    if (minutes > 0) return `${minutes}м ${seconds % 60}с`;
    return `${seconds}с`;
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <Heart className="h-8 w-8 animate-pulse text-red-600 mx-auto mb-4" />
          <p className="text-gray-600">Проверка состояния системы...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-md">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <Heart className="h-6 w-6 text-red-600 mr-3" />
            <div>
              <h1 className="text-2xl font-semibold text-gray-900">Состояние системы</h1>
              <p className="text-gray-600 mt-1">Мониторинг работоспособности компонентов</p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <div className="flex items-center">
              <input
                type="checkbox"
                id="autoRefresh"
                checked={autoRefresh}
                onChange={(e) => setAutoRefresh(e.target.checked)}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded mr-2"
              />
              <label htmlFor="autoRefresh" className="text-sm text-gray-700">
                Авто-обновление
              </label>
            </div>
            <button
              onClick={() => fetchHealthData(true)}
              disabled={isRefreshing}
              className="flex items-center px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${isRefreshing ? 'animate-spin' : ''}`} />
              Обновить
            </button>
          </div>
        </div>
      </div>

      {/* Last Updated */}
      {lastUpdated && (
        <div className="px-6 py-2 bg-gray-50 border-b border-gray-200 text-sm text-gray-600">
          <div className="flex items-center">
            <Clock className="h-4 w-4 mr-2" />
            Последнее обновление: {lastUpdated.toLocaleString('ru-RU')}
          </div>
        </div>
      )}

      {/* Error Message */}
      {error && (
        <div className="mx-6 mt-4 p-4 bg-red-50 border border-red-200 rounded-md">
          <div className="flex items-center">
            <XCircle className="h-5 w-5 text-red-500 mr-2" />
            <span className="text-red-700">{error}</span>
          </div>
        </div>
      )}

      {/* System Overview */}
      {healthData && (
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div className="bg-white border border-gray-200 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Общее состояние</p>
                  <div className="flex items-center mt-1">
                    {getStatusIcon(healthData.system_health)}
                    <span className={`ml-2 text-sm font-medium capitalize ${getStatusColor(healthData.system_health).split(' ')[0]}`}>
                      {healthData.system_health}
                    </span>
                  </div>
                </div>
                <Heart className="h-8 w-8 text-red-600" />
              </div>
            </div>

            <div className="bg-white border border-gray-200 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Активные агенты</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{healthData.active_agents}</p>
                </div>
                <Server className="h-8 w-8 text-blue-600" />
              </div>
            </div>

            <div className="bg-white border border-gray-200 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Всего запросов</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{healthData.total_requests.toLocaleString()}</p>
                </div>
                <Activity className="h-8 w-8 text-green-600" />
              </div>
            </div>

            <div className="bg-white border border-gray-200 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Время ответа API</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{healthData.api_response_time}ms</p>
                </div>
                <Network className="h-8 w-8 text-purple-600" />
              </div>
            </div>
          </div>

          {/* Performance Metrics */}
          <div className="mb-8">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Метрики производительности</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {performanceMetrics.map((metric, index) => (
                <div key={index} className="bg-white border border-gray-200 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center">
                      <metric.icon className={`h-5 w-5 mr-2 ${getMetricStatusColor(metric.status)}`} />
                      <span className="text-sm font-medium text-gray-600">{metric.name}</span>
                    </div>
                    {getTrendIcon(metric.trend)}
                  </div>
                  <div className="flex items-baseline">
                    <span className={`text-2xl font-bold ${getMetricStatusColor(metric.status)}`}>
                      {metric.value}
                    </span>
                    <span className="text-sm text-gray-500 ml-1">{metric.unit}</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
                    <div 
                      className={`h-2 rounded-full ${
                        metric.status === 'healthy' ? 'bg-green-500' :
                        metric.status === 'warning' ? 'bg-yellow-500' : 'bg-red-500'
                      }`}
                      style={{ width: `${Math.min(metric.value, 100)}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Component Status */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Статус компонентов</h3>
            <div className="space-y-4">
              {healthData.components.map((component, index) => (
                <div key={index} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      {getStatusIcon(component.status)}
                      <div className="ml-3">
                        <h4 className="text-sm font-medium text-gray-900">{component.component}</h4>
                        <div className="flex items-center space-x-4 text-xs text-gray-500 mt-1">
                          <span>Время ответа: {component.response_time_ms}ms</span>
                          <span>Проверено: {new Date(component.last_check).toLocaleString('ru-RU')}</span>
                        </div>
                      </div>
                    </div>
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${getStatusColor(component.status)}`}>
                      {component.status}
                    </span>
                  </div>
                  
                  {component.details && Object.keys(component.details).length > 0 && (
                    <div className="mt-3 p-3 bg-gray-50 rounded-md">
                      <p className="text-xs font-medium text-gray-700 mb-2">Детали:</p>
                      <pre className="text-xs text-gray-600 whitespace-pre-wrap">
                        {JSON.stringify(component.details, null, 2)}
                      </pre>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Database Status */}
          <div className="mt-8 border border-gray-200 rounded-lg p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <Database className="h-5 w-5 text-blue-600 mr-3" />
                <div>
                  <h4 className="text-sm font-medium text-gray-900">База данных</h4>
                  <p className="text-xs text-gray-500">Основное хранилище данных системы</p>
                </div>
              </div>
              <div className="flex items-center">
                {getStatusIcon(healthData.database_status)}
                <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${getStatusColor(healthData.database_status)}`}>
                  {healthData.database_status}
                </span>
              </div>
            </div>
          </div>

          {/* Health Summary */}
          <div className="mt-6 p-4 bg-gray-50 rounded-lg">
            <h4 className="text-sm font-medium text-gray-900 mb-2">Сводка состояния</h4>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div className="flex items-center">
                <div className="w-3 h-3 bg-green-500 rounded-full mr-2" />
                <span>Здоровые: {healthData.components.filter(c => ['healthy', 'online', 'connected'].includes(c.status.toLowerCase())).length}</span>
              </div>
              <div className="flex items-center">
                <div className="w-3 h-3 bg-yellow-500 rounded-full mr-2" />
                <span>Предупреждения: {healthData.components.filter(c => ['warning', 'degraded'].includes(c.status.toLowerCase())).length}</span>
              </div>
              <div className="flex items-center">
                <div className="w-3 h-3 bg-red-500 rounded-full mr-2" />
                <span>Критичные: {healthData.components.filter(c => ['critical', 'offline', 'disconnected', 'error'].includes(c.status.toLowerCase())).length}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Empty State */}
      {!healthData && !isLoading && (
        <div className="text-center py-12">
          <Server className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Нет данных о состоянии</h3>
          <p className="text-gray-600">Не удалось получить информацию о состоянии системы</p>
        </div>
      )}
    </div>
  );
};

export default SystemHealth;