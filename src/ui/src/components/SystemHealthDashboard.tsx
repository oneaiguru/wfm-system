import React, { useState, useEffect } from 'react';
import { 
  Heart, Server, Database, Cpu, MemoryStick, HardDrive, Network, RefreshCw, 
  AlertTriangle, CheckCircle, XCircle, Clock, TrendingUp, Activity, 
  Shield, Users, Globe, Zap, BarChart3, Settings, Cloud, Loader2
} from 'lucide-react';

interface SystemComponent {
  component: string;
  status: 'healthy' | 'warning' | 'critical' | 'offline';
  last_check: string;
  response_time_ms: number;
  uptime_percentage: number;
  error_count: number;
  details: {
    version?: string;
    endpoint?: string;
    error?: string;
    memory_usage?: number;
    cpu_usage?: number;
  };
}

interface IntegrationHealth {
  service_name: string;
  status: 'connected' | 'degraded' | 'failed';
  last_sync: string;
  sync_frequency: string;
  data_quality: number;
  error_rate: number;
  integration_type: 'api' | 'database' | 'file' | 'webhook';
}

interface SystemArchitectureHealth {
  overall_status: 'healthy' | 'degraded' | 'critical';
  system_uptime: number;
  total_requests_24h: number;
  average_response_time: number;
  error_rate_24h: number;
  active_users: number;
  database_connections: number;
  cache_hit_ratio: number;
  components: SystemComponent[];
  integrations: IntegrationHealth[];
  security_alerts: number;
  performance_score: number;
  last_updated: string;
}

interface AlertMetric {
  type: 'performance' | 'security' | 'integration' | 'system';
  severity: 'low' | 'medium' | 'high' | 'critical';
  message: string;
  timestamp: string;
  component: string;
  acknowledged: boolean;
}

// SPEC-09 Enterprise Architecture translations
const translations = {
  title: 'Мониторинг Архитектуры Системы',
  subtitle: 'Интегрированная панель состояния предприятия',
  tabs: {
    overview: 'Обзор',
    components: 'Компоненты',
    integrations: 'Интеграции', 
    performance: 'Производительность',
    security: 'Безопасность',
    alerts: 'Предупреждения'
  },
  status: {
    healthy: 'Здоров',
    warning: 'Предупреждение',
    critical: 'Критический',
    offline: 'Отключен',
    connected: 'Подключен',
    degraded: 'Снижена',
    failed: 'Сбой'
  },
  metrics: {
    systemUptime: 'Время работы системы',
    totalRequests: 'Запросов за 24ч',
    responseTime: 'Время отклика',
    errorRate: 'Частота ошибок',
    activeUsers: 'Активных пользователей',
    dbConnections: 'Соединений с БД',
    cacheHitRatio: 'Эффективность кэша',
    performanceScore: 'Индекс производительности',
    securityAlerts: 'Предупреждения безопасности'
  },
  components: {
    'API Gateway': 'API Шлюз',
    'Auth Service': 'Служба Аутентификации',
    'Database': 'База Данных',
    'Cache Layer': 'Слой Кэширования',
    'File Storage': 'Файловое Хранилище',
    'Message Queue': 'Очередь Сообщений',
    'Load Balancer': 'Балансировщик Нагрузки'
  },
  integrations: {
    '1C_ZUP': '1C ЗУП (Зарплата и Управление Персоналом)',
    'AD_LDAP': 'Active Directory / LDAP',
    'Email_Service': 'Почтовая Служба',
    'SMS_Gateway': 'SMS Шлюз',
    'File_Exchange': 'Файловый Обмен',
    'External_API': 'Внешние API'
  }
};

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

export const SystemHealthDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'overview' | 'components' | 'integrations' | 'performance' | 'security' | 'alerts'>('overview');
  const [healthData, setHealthData] = useState<SystemArchitectureHealth | null>(null);
  const [alerts, setAlerts] = useState<AlertMetric[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string>('');
  const [autoRefresh, setAutoRefresh] = useState(true);

  useEffect(() => {
    loadSystemHealth();
    
    let interval: NodeJS.Timeout;
    if (autoRefresh) {
      interval = setInterval(loadSystemHealth, 30000); // 30 second refresh
    }
    
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [autoRefresh]);

  const loadSystemHealth = async () => {
    if (healthData) setRefreshing(true);
    else setLoading(true);
    
    setError('');
    
    try {
      // Try SPEC-09 formal endpoint when available
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/system/health/architecture`, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data: SystemArchitectureHealth = await response.json();
        setHealthData(data);
        
        // Load alerts
        const alertsResponse = await fetch(`${API_BASE_URL}/system/alerts/active`, {
          headers: { 'Authorization': `Bearer ${authToken}` }
        });
        
        if (alertsResponse.ok) {
          const alertsData = await alertsResponse.json();
          setAlerts(alertsData.alerts || []);
        }
        
        console.log('✅ SPEC-09 system architecture health loaded:', data);
      } else {
        // Use comprehensive demo data for SPEC-09
        console.log('⚠️ SPEC-09 APIs not available, using enterprise demo data');
        setHealthData(generateEnterpriseHealthData());
        setAlerts(generateDemoAlerts());
        setError('Демо данные - SPEC-09 APIs в разработке');
      }
    } catch (err) {
      console.log('⚠️ System health API error, using demo data');
      setHealthData(generateEnterpriseHealthData());
      setAlerts(generateDemoAlerts());
      setError('Сетевая ошибка - использование демо данных');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const generateEnterpriseHealthData = (): SystemArchitectureHealth => {
    return {
      overall_status: 'healthy',
      system_uptime: 99.7,
      total_requests_24h: 847293,
      average_response_time: 127,
      error_rate_24h: 0.03,
      active_users: 1247,
      database_connections: 23,
      cache_hit_ratio: 94.8,
      performance_score: 92,
      security_alerts: 2,
      last_updated: new Date().toISOString(),
      components: [
        {
          component: 'API Gateway',
          status: 'healthy',
          last_check: new Date().toISOString(),
          response_time_ms: 45,
          uptime_percentage: 99.9,
          error_count: 12,
          details: { version: '2.3.1', endpoint: '/api/v1', cpu_usage: 32, memory_usage: 68 }
        },
        {
          component: 'Auth Service',
          status: 'healthy',
          last_check: new Date().toISOString(),
          response_time_ms: 23,
          uptime_percentage: 99.8,
          error_count: 3,
          details: { version: '1.7.2', endpoint: '/auth', cpu_usage: 18, memory_usage: 45 }
        },
        {
          component: 'Database',
          status: 'warning',
          last_check: new Date().toISOString(),
          response_time_ms: 89,
          uptime_percentage: 99.2,
          error_count: 47,
          details: { version: 'PostgreSQL 15.3', cpu_usage: 67, memory_usage: 78 }
        },
        {
          component: 'Cache Layer',
          status: 'healthy',
          last_check: new Date().toISOString(),
          response_time_ms: 8,
          uptime_percentage: 99.9,
          error_count: 1,
          details: { version: 'Redis 7.0', cpu_usage: 12, memory_usage: 34 }
        },
        {
          component: 'File Storage',
          status: 'healthy',
          last_check: new Date().toISOString(),
          response_time_ms: 156,
          uptime_percentage: 99.6,
          error_count: 8,
          details: { version: 'MinIO 2023.7', cpu_usage: 23, memory_usage: 56 }
        }
      ],
      integrations: [
        {
          service_name: '1C_ZUP',
          status: 'connected',
          last_sync: new Date(Date.now() - 300000).toISOString(), // 5 mins ago
          sync_frequency: 'Every 15 minutes',
          data_quality: 98.5,
          error_rate: 0.2,
          integration_type: 'api'
        },
        {
          service_name: 'AD_LDAP',
          status: 'connected',
          last_sync: new Date(Date.now() - 120000).toISOString(), // 2 mins ago
          sync_frequency: 'Real-time',
          data_quality: 99.8,
          error_rate: 0.05,
          integration_type: 'api'
        },
        {
          service_name: 'Email_Service',
          status: 'degraded',
          last_sync: new Date(Date.now() - 900000).toISOString(), // 15 mins ago
          sync_frequency: 'On demand',
          data_quality: 94.2,
          error_rate: 2.1,
          integration_type: 'webhook'
        },
        {
          service_name: 'SMS_Gateway',
          status: 'connected',
          last_sync: new Date(Date.now() - 60000).toISOString(), // 1 min ago
          sync_frequency: 'Real-time',
          data_quality: 97.6,
          error_rate: 0.8,
          integration_type: 'api'
        }
      ]
    };
  };

  const generateDemoAlerts = (): AlertMetric[] => {
    return [
      {
        type: 'performance',
        severity: 'medium',
        message: 'Высокая загрузка базы данных (78% памяти)',
        timestamp: new Date(Date.now() - 600000).toISOString(),
        component: 'Database',
        acknowledged: false
      },
      {
        type: 'integration',
        severity: 'high',
        message: 'Снижена производительность Email Service (94.2% качества данных)',
        timestamp: new Date(Date.now() - 900000).toISOString(),
        component: 'Email_Service',
        acknowledged: false
      },
      {
        type: 'security',
        severity: 'low',
        message: 'Обнаружены неудачные попытки входа (47 за последний час)',
        timestamp: new Date(Date.now() - 3600000).toISOString(),
        component: 'Auth Service',
        acknowledged: true
      }
    ];
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy':
      case 'connected':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'warning':
      case 'degraded':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'critical':
      case 'failed':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'offline':
        return 'bg-gray-100 text-gray-800 border-gray-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy':
      case 'connected':
        return <CheckCircle className="h-4 w-4 text-green-600" />;
      case 'warning':
      case 'degraded':
        return <AlertTriangle className="h-4 w-4 text-yellow-600" />;
      case 'critical':
      case 'failed':
        return <XCircle className="h-4 w-4 text-red-600" />;
      case 'offline':
        return <XCircle className="h-4 w-4 text-gray-600" />;
      default:
        return <Activity className="h-4 w-4 text-gray-600" />;
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

  const formatUptime = (percentage: number) => {
    const days = Math.floor(percentage * 30.44 / 100); // Approximate days in month
    const hours = Math.floor((percentage * 30.44 * 24 / 100) % 24);
    return `${days}д ${hours}ч`;
  };

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-300 rounded w-1/3"></div>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="h-32 bg-gray-300 rounded"></div>
            ))}
          </div>
          <div className="h-64 bg-gray-300 rounded"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6" data-testid="system-health-dashboard">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Shield className="h-6 w-6 text-blue-600" />
            <div>
              <h1 className="text-2xl font-semibold text-gray-900">{translations.title}</h1>
              <p className="text-gray-600">
                {healthData ? 
                  `${translations.subtitle} • Обновлено ${new Date(healthData.last_updated).toLocaleString('ru-RU')}` :
                  translations.subtitle
                }
                {error && <span className="text-yellow-600 ml-2">• {error}</span>}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            <label className="flex items-center gap-2 text-sm text-gray-600">
              <input
                type="checkbox"
                checked={autoRefresh}
                onChange={(e) => setAutoRefresh(e.target.checked)}
                className="rounded"
              />
              Автообновление
            </label>
            <button
              onClick={loadSystemHealth}
              disabled={refreshing}
              className="flex items-center gap-2 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
            >
              {refreshing ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
              Обновить
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

      {/* Overview Tab */}
      {activeTab === 'overview' && healthData && (
        <div className="space-y-6">
          {/* Key Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-white rounded-lg p-6 shadow-sm border">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">{translations.metrics.systemUptime}</p>
                  <p className="text-2xl font-bold text-green-600">{healthData.system_uptime}%</p>
                </div>
                <Heart className="h-8 w-8 text-green-600" />
              </div>
            </div>
            
            <div className="bg-white rounded-lg p-6 shadow-sm border">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">{translations.metrics.totalRequests}</p>
                  <p className="text-2xl font-bold text-blue-600">{healthData.total_requests_24h.toLocaleString('ru-RU')}</p>
                </div>
                <BarChart3 className="h-8 w-8 text-blue-600" />
              </div>
            </div>
            
            <div className="bg-white rounded-lg p-6 shadow-sm border">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">{translations.metrics.responseTime}</p>
                  <p className="text-2xl font-bold text-purple-600">{healthData.average_response_time}ms</p>
                </div>
                <Zap className="h-8 w-8 text-purple-600" />
              </div>
            </div>
            
            <div className="bg-white rounded-lg p-6 shadow-sm border">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">{translations.metrics.performanceScore}</p>
                  <p className="text-2xl font-bold text-green-600">{healthData.performance_score}/100</p>
                </div>
                <TrendingUp className="h-8 w-8 text-green-600" />
              </div>
            </div>
          </div>

          {/* System Overview */}
          <div className="bg-white rounded-lg shadow-sm border">
            <div className="p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Состояние Системы</h2>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <h3 className="font-medium text-gray-900">Основные Компоненты</h3>
                  {healthData.components.slice(0, 3).map((component) => (
                    <div key={component.component} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <div className="flex items-center gap-3">
                        {getStatusIcon(component.status)}
                        <div>
                          <p className="font-medium text-gray-900">
                            {translations.components[component.component as keyof typeof translations.components] || component.component}
                          </p>
                          <p className="text-sm text-gray-600">
                            {component.response_time_ms}ms • {component.uptime_percentage}% uptime
                          </p>
                        </div>
                      </div>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full border ${getStatusColor(component.status)}`}>
                        {translations.status[component.status as keyof typeof translations.status]}
                      </span>
                    </div>
                  ))}
                </div>
                
                <div className="space-y-4">
                  <h3 className="font-medium text-gray-900">Ключевые Интеграции</h3>
                  {healthData.integrations.slice(0, 3).map((integration) => (
                    <div key={integration.service_name} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <div className="flex items-center gap-3">
                        {getStatusIcon(integration.status)}
                        <div>
                          <p className="font-medium text-gray-900">
                            {translations.integrations[integration.service_name as keyof typeof translations.integrations] || integration.service_name}
                          </p>
                          <p className="text-sm text-gray-600">
                            Качество: {integration.data_quality}% • Ошибки: {integration.error_rate}%
                          </p>
                        </div>
                      </div>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full border ${getStatusColor(integration.status)}`}>
                        {translations.status[integration.status as keyof typeof translations.status]}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Components Tab */}
      {activeTab === 'components' && healthData && (
        <div className="bg-white rounded-lg shadow-sm border">
          <div className="p-6 border-b">
            <h2 className="text-lg font-semibold text-gray-900">Компоненты Системы</h2>
          </div>
          <div className="p-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              {healthData.components.map((component) => (
                <div key={component.component} className="p-4 border border-gray-200 rounded-lg">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      {getStatusIcon(component.status)}
                      <h3 className="font-medium text-gray-900">
                        {translations.components[component.component as keyof typeof translations.components] || component.component}
                      </h3>
                    </div>
                    <span className={`px-2 py-1 text-xs font-medium rounded-full border ${getStatusColor(component.status)}`}>
                      {translations.status[component.status as keyof typeof translations.status]}
                    </span>
                  </div>
                  
                  <div className="space-y-2 text-sm text-gray-600">
                    <div className="flex justify-between">
                      <span>Время отклика:</span>
                      <span className="font-medium">{component.response_time_ms}ms</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Время работы:</span>
                      <span className="font-medium">{component.uptime_percentage}%</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Ошибки (24ч):</span>
                      <span className="font-medium">{component.error_count}</span>
                    </div>
                    {component.details.version && (
                      <div className="flex justify-between">
                        <span>Версия:</span>
                        <span className="font-medium">{component.details.version}</span>
                      </div>
                    )}
                    {component.details.cpu_usage && (
                      <div className="flex justify-between">
                        <span>CPU:</span>
                        <span className="font-medium">{component.details.cpu_usage}%</span>
                      </div>
                    )}
                    {component.details.memory_usage && (
                      <div className="flex justify-between">
                        <span>Память:</span>
                        <span className="font-medium">{component.details.memory_usage}%</span>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Integrations Tab */}
      {activeTab === 'integrations' && healthData && (
        <div className="bg-white rounded-lg shadow-sm border">
          <div className="p-6 border-b">
            <h2 className="text-lg font-semibold text-gray-900">Интеграции Предприятия</h2>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {healthData.integrations.map((integration) => (
                <div key={integration.service_name} className="p-4 border border-gray-200 rounded-lg">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      {getStatusIcon(integration.status)}
                      <h3 className="font-medium text-gray-900">
                        {translations.integrations[integration.service_name as keyof typeof translations.integrations] || integration.service_name}
                      </h3>
                    </div>
                    <span className={`px-2 py-1 text-xs font-medium rounded-full border ${getStatusColor(integration.status)}`}>
                      {translations.status[integration.status as keyof typeof translations.status]}
                    </span>
                  </div>
                  
                  <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 text-sm text-gray-600">
                    <div>
                      <span className="block text-gray-500">Последняя синхронизация:</span>
                      <span className="font-medium">{new Date(integration.last_sync).toLocaleString('ru-RU')}</span>
                    </div>
                    <div>
                      <span className="block text-gray-500">Частота:</span>
                      <span className="font-medium">{integration.sync_frequency}</span>
                    </div>
                    <div>
                      <span className="block text-gray-500">Качество данных:</span>
                      <span className="font-medium">{integration.data_quality}%</span>
                    </div>
                    <div>
                      <span className="block text-gray-500">Частота ошибок:</span>
                      <span className="font-medium">{integration.error_rate}%</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Alerts Tab */}
      {activeTab === 'alerts' && (
        <div className="bg-white rounded-lg shadow-sm border">
          <div className="p-6 border-b">
            <h2 className="text-lg font-semibold text-gray-900">Системные Предупреждения</h2>
          </div>
          <div className="p-6">
            {alerts.length === 0 ? (
              <div className="text-center py-8">
                <CheckCircle className="h-12 w-12 text-green-400 mx-auto mb-3" />
                <p className="text-gray-500">Нет активных предупреждений</p>
              </div>
            ) : (
              <div className="space-y-4">
                {alerts.map((alert, index) => (
                  <div key={index} className={`p-4 border rounded-lg ${getSeverityColor(alert.severity)}`}>
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <AlertTriangle className="h-4 w-4" />
                          <span className="font-medium">{alert.component}</span>
                          <span className={`px-2 py-1 text-xs font-medium rounded-full ${getSeverityColor(alert.severity)}`}>
                            {alert.severity.toUpperCase()}
                          </span>
                        </div>
                        <p className="text-sm mb-2">{alert.message}</p>
                        <p className="text-xs opacity-75">
                          {new Date(alert.timestamp).toLocaleString('ru-RU')}
                        </p>
                      </div>
                      {!alert.acknowledged && (
                        <button className="text-xs px-3 py-1 bg-white bg-opacity-50 rounded hover:bg-opacity-75">
                          Подтвердить
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default SystemHealthDashboard;