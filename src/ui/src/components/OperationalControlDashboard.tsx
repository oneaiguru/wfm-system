import React, { useState, useEffect } from 'react';
import {
  Monitor,
  Users,
  Phone,
  Clock,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  CheckCircle,
  XCircle,
  RefreshCw,
  Settings,
  Filter,
  Download,
  Globe,
  Activity,
  Gauge,
  Bell,
  BellOff,
  Eye,
  EyeOff,
  Maximize2,
  Minimize2,
  Play,
  Pause,
  BarChart3,
  PieChart,
  Calendar,
  Search,
  User,
  UserCheck,
  UserX,
  Coffee,
  Headphones,
  PhoneCall,
  Timer,
  Target,
  Zap,
  AlertCircle,
  Info
} from 'lucide-react';
import realOperationalService, { 
  OperationalMetrics, 
  AgentStatus, 
  QueueMetrics, 
  AlertItem, 
  DrillDownData,
  RealTimeUpdate 
} from '../services/realOperationalService';

// Russian translations per BDD requirements
const translations = {
  ru: {
    title: 'Операционная панель контроля',
    subtitle: 'Мониторинг в реальном времени',
    keyMetrics: 'Ключевые метрики',
    agentStatus: 'Статус агентов',
    queueStatus: 'Статус очередей',
    alerts: 'Уведомления',
    drillDown: 'Детализация',
    settings: 'Настройки',
    refresh: 'Обновить',
    export: 'Экспорт',
    filter: 'Фильтр',
    search: 'Поиск...',
    loading: 'Загрузка...',
    error: 'Ошибка',
    noData: 'Нет данных',
    lastUpdate: 'Последнее обновление',
    autoRefresh: 'Автообновление',
    realTime: 'Реальное время',
    
    // Metrics
    metrics: {
      serviceLevel: 'Уровень сервиса',
      averageHandleTime: 'Среднее время обработки',
      queueVolume: 'Объем очереди',
      staffingLevel: 'Уровень персонала',
      responseTime: 'Время ответа',
      customerSatisfaction: 'Удовлетворенность клиентов'
    },
    
    // Agent states
    agentStates: {
      available: 'Доступен',
      busy: 'Занят',
      break: 'Перерыв',
      offline: 'Не в сети',
      after_call_work: 'После звонка'
    },
    
    // Queue status
    queueStatus: {
      normal: 'Нормальная',
      warning: 'Предупреждение',
      critical: 'Критическая'
    },
    
    // Alert types
    alertTypes: {
      threshold: 'Превышение лимита',
      predictive: 'Прогнозирование',
      system: 'Система',
      performance: 'Производительность'
    },
    
    // Alert severity
    alertSeverity: {
      low: 'Низкая',
      medium: 'Средняя',
      high: 'Высокая',
      critical: 'Критическая'
    },
    
    // Status indicators
    status: {
      green: 'Отлично',
      yellow: 'Предупреждение',
      red: 'Критическое',
      up: 'Рост',
      down: 'Снижение',
      stable: 'Стабильно'
    },
    
    // Actions
    actions: {
      acknowledge: 'Подтвердить',
      resolve: 'Решить',
      view: 'Просмотреть',
      edit: 'Редактировать',
      delete: 'Удалить',
      assign: 'Назначить',
      transfer: 'Перевести',
      break: 'Перерыв',
      login: 'Войти',
      logout: 'Выйти',
      details: 'Подробности',
      history: 'История',
      forecast: 'Прогноз'
    },
    
    // Time ranges
    timeRanges: {
      '5m': '5 минут',
      '15m': '15 минут',
      '1h': '1 час',
      '4h': '4 часа',
      '1d': '1 день',
      '1w': '1 неделя'
    },
    
    // Units
    units: {
      percent: '%',
      seconds: 'сек',
      minutes: 'мин',
      hours: 'ч',
      calls: 'звонков',
      agents: 'агентов',
      rating: 'рейтинг'
    },
    
    // Dashboard sections
    sections: {
      overview: 'Обзор',
      detailed: 'Подробно',
      trends: 'Тренды',
      forecasts: 'Прогнозы',
      alerts: 'Уведомления',
      agents: 'Агенты',
      queues: 'Очереди',
      performance: 'Производительность'
    }
  },
  en: {
    title: 'Operational Control Dashboard',
    subtitle: 'Real-time monitoring',
    keyMetrics: 'Key Metrics',
    agentStatus: 'Agent Status',
    queueStatus: 'Queue Status',
    alerts: 'Alerts',
    drillDown: 'Drill Down',
    settings: 'Settings',
    refresh: 'Refresh',
    export: 'Export',
    filter: 'Filter',
    search: 'Search...',
    loading: 'Loading...',
    error: 'Error',
    noData: 'No Data',
    lastUpdate: 'Last Update',
    autoRefresh: 'Auto Refresh',
    realTime: 'Real Time',
    
    // Metrics
    metrics: {
      serviceLevel: 'Service Level',
      averageHandleTime: 'Average Handle Time',
      queueVolume: 'Queue Volume',
      staffingLevel: 'Staffing Level',
      responseTime: 'Response Time',
      customerSatisfaction: 'Customer Satisfaction'
    },
    
    // Agent states
    agentStates: {
      available: 'Available',
      busy: 'Busy',
      break: 'Break',
      offline: 'Offline',
      after_call_work: 'After Call Work'
    },
    
    // Queue status
    queueStatus: {
      normal: 'Normal',
      warning: 'Warning',
      critical: 'Critical'
    },
    
    // Alert types
    alertTypes: {
      threshold: 'Threshold',
      predictive: 'Predictive',
      system: 'System',
      performance: 'Performance'
    },
    
    // Alert severity
    alertSeverity: {
      low: 'Low',
      medium: 'Medium',
      high: 'High',
      critical: 'Critical'
    },
    
    // Status indicators
    status: {
      green: 'Excellent',
      yellow: 'Warning',
      red: 'Critical',
      up: 'Up',
      down: 'Down',
      stable: 'Stable'
    },
    
    // Actions
    actions: {
      acknowledge: 'Acknowledge',
      resolve: 'Resolve',
      view: 'View',
      edit: 'Edit',
      delete: 'Delete',
      assign: 'Assign',
      transfer: 'Transfer',
      break: 'Break',
      login: 'Login',
      logout: 'Logout',
      details: 'Details',
      history: 'History',
      forecast: 'Forecast'
    },
    
    // Time ranges
    timeRanges: {
      '5m': '5 minutes',
      '15m': '15 minutes',
      '1h': '1 hour',
      '4h': '4 hours',
      '1d': '1 day',
      '1w': '1 week'
    },
    
    // Units
    units: {
      percent: '%',
      seconds: 'sec',
      minutes: 'min',
      hours: 'h',
      calls: 'calls',
      agents: 'agents',
      rating: 'rating'
    },
    
    // Dashboard sections
    sections: {
      overview: 'Overview',
      detailed: 'Detailed',
      trends: 'Trends',
      forecasts: 'Forecasts',
      alerts: 'Alerts',
      agents: 'Agents',
      queues: 'Queues',
      performance: 'Performance'
    }
  }
};

interface OperationalControlDashboardProps {
  initialView?: 'overview' | 'detailed' | 'agents' | 'queues' | 'alerts';
  autoRefresh?: boolean;
  refreshInterval?: number;
  onMetricClick?: (metricId: string) => void;
  onAgentClick?: (agentId: string) => void;
  onQueueClick?: (queueId: string) => void;
  onAlertClick?: (alertId: string) => void;
}

const OperationalControlDashboard: React.FC<OperationalControlDashboardProps> = ({
  initialView = 'overview',
  autoRefresh = true,
  refreshInterval = 30000,
  onMetricClick,
  onAgentClick,
  onQueueClick,
  onAlertClick
}) => {
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const [activeView, setActiveView] = useState(initialView);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string>('');
  const [lastUpdate, setLastUpdate] = useState<string>('');
  const [isRealTimeEnabled, setIsRealTimeEnabled] = useState(true);
  const [isPaused, setIsPaused] = useState(false);
  
  // Data state
  const [metrics, setMetrics] = useState<OperationalMetrics | null>(null);
  const [agents, setAgents] = useState<AgentStatus[]>([]);
  const [queues, setQueues] = useState<QueueMetrics[]>([]);
  const [alerts, setAlerts] = useState<AlertItem[]>([]);
  const [drillDownData, setDrillDownData] = useState<DrillDownData | null>(null);
  
  // Filter state
  const [agentFilter, setAgentFilter] = useState<string>('all');
  const [queueFilter, setQueueFilter] = useState<string>('all');
  const [alertFilter, setAlertFilter] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');
  
  // UI state
  const [expandedMetric, setExpandedMetric] = useState<string | null>(null);
  const [showSettings, setShowSettings] = useState(false);
  const [selectedTimeRange, setSelectedTimeRange] = useState('1h');
  
  const t = translations[language];

  useEffect(() => {
    loadInitialData();
    
    if (autoRefresh && !isPaused) {
      const interval = setInterval(loadInitialData, refreshInterval);
      return () => clearInterval(interval);
    }
  }, [autoRefresh, isPaused, refreshInterval]);

  useEffect(() => {
    if (isRealTimeEnabled) {
      const cleanup = realOperationalService.connectRealTimeUpdates();
      const unsubscribe = realOperationalService.subscribeToUpdates(handleRealTimeUpdate);
      
      return () => {
        cleanup();
        unsubscribe();
      };
    }
  }, [isRealTimeEnabled]);

  const loadInitialData = async () => {
    setIsLoading(true);
    setError('');
    
    try {
      const [metricsResult, agentsResult, queuesResult, alertsResult] = await Promise.all([
        realOperationalService.getCurrentMetrics(),
        realOperationalService.getAgentStatuses(),
        realOperationalService.getQueueMetrics(),
        realOperationalService.getActiveAlerts()
      ]);
      
      if (metricsResult.success && metricsResult.data) {
        setMetrics(metricsResult.data);
      }
      
      if (agentsResult.success && agentsResult.data) {
        setAgents(agentsResult.data);
      }
      
      if (queuesResult.success && queuesResult.data) {
        setQueues(queuesResult.data);
      }
      
      if (alertsResult.success && alertsResult.data) {
        setAlerts(alertsResult.data);
      }
      
      setLastUpdate(new Date().toLocaleString());
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load dashboard data');
    } finally {
      setIsLoading(false);
    }
  };

  const handleRealTimeUpdate = (update: RealTimeUpdate) => {
    console.log('Real-time update received:', update);
    
    switch (update.type) {
      case 'metrics':
        setMetrics(update.data);
        break;
      case 'agent_status':
        setAgents(prev => prev.map(agent => 
          agent.id === update.data.id ? { ...agent, ...update.data } : agent
        ));
        break;
      case 'queue_status':
        setQueues(prev => prev.map(queue => 
          queue.queueId === update.data.queueId ? { ...queue, ...update.data } : queue
        ));
        break;
      case 'alert':
        setAlerts(prev => [update.data, ...prev]);
        break;
    }
    
    setLastUpdate(new Date().toLocaleString());
  };

  const handleMetricClick = async (metricId: string) => {
    if (onMetricClick) {
      onMetricClick(metricId);
    }
    
    // Toggle expanded view
    if (expandedMetric === metricId) {
      setExpandedMetric(null);
      setDrillDownData(null);
    } else {
      setExpandedMetric(metricId);
      
      try {
        const result = await realOperationalService.getDrillDownData(metricId, selectedTimeRange, '15min');
        if (result.success && result.data) {
          setDrillDownData(result.data);
        }
      } catch (err) {
        console.error('Failed to load drill-down data:', err);
      }
    }
  };

  const handleAgentAction = async (agentId: string, action: string) => {
    try {
      const result = await realOperationalService.updateAgentState(agentId, action);
      if (result.success) {
        // Refresh agent data
        const agentsResult = await realOperationalService.getAgentStatuses();
        if (agentsResult.success && agentsResult.data) {
          setAgents(agentsResult.data);
        }
      }
    } catch (err) {
      console.error('Failed to update agent state:', err);
    }
  };

  const handleAlertAction = async (alertId: string, action: 'acknowledge' | 'resolve') => {
    try {
      let result;
      if (action === 'acknowledge') {
        result = await realOperationalService.acknowledgeAlert(alertId);
      } else {
        result = await realOperationalService.resolveAlert(alertId, 'Resolved from dashboard');
      }
      
      if (result.success) {
        // Refresh alerts
        const alertsResult = await realOperationalService.getActiveAlerts();
        if (alertsResult.success && alertsResult.data) {
          setAlerts(alertsResult.data);
        }
      }
    } catch (err) {
      console.error('Failed to update alert:', err);
    }
  };

  const handleRefresh = async () => {
    await loadInitialData();
  };

  const handleExport = async () => {
    try {
      const result = await realOperationalService.exportMetrics('excel', selectedTimeRange);
      if (result.success && result.data) {
        // Download file
        const link = document.createElement('a');
        link.href = result.data.url;
        link.download = result.data.filename;
        link.click();
      }
    } catch (err) {
      console.error('Failed to export metrics:', err);
    }
  };

  const getMetricIcon = (metricKey: string) => {
    switch (metricKey) {
      case 'serviceLevel': return Target;
      case 'averageHandleTime': return Timer;
      case 'queueVolume': return Phone;
      case 'staffingLevel': return Users;
      case 'responseTime': return Zap;
      case 'customerSatisfaction': return CheckCircle;
      default: return Activity;
    }
  };

  const getMetricColor = (status: string) => {
    switch (status) {
      case 'green': return 'text-green-600 bg-green-50 border-green-200';
      case 'yellow': return 'text-yellow-600 bg-yellow-50 border-yellow-200';
      case 'red': return 'text-red-600 bg-red-50 border-red-200';
      default: return 'text-gray-600 bg-gray-50 border-gray-200';
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return TrendingUp;
      case 'down': return TrendingDown;
      default: return Activity;
    }
  };

  const getAgentStateIcon = (state: string) => {
    switch (state) {
      case 'available': return UserCheck;
      case 'busy': return PhoneCall;
      case 'break': return Coffee;
      case 'offline': return UserX;
      case 'after_call_work': return Headphones;
      default: return User;
    }
  };

  const getAgentStateColor = (state: string) => {
    switch (state) {
      case 'available': return 'text-green-600 bg-green-50';
      case 'busy': return 'text-blue-600 bg-blue-50';
      case 'break': return 'text-yellow-600 bg-yellow-50';
      case 'offline': return 'text-gray-600 bg-gray-50';
      case 'after_call_work': return 'text-purple-600 bg-purple-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const getQueueStatusColor = (status: string) => {
    switch (status) {
      case 'normal': return 'text-green-600 bg-green-50';
      case 'warning': return 'text-yellow-600 bg-yellow-50';
      case 'critical': return 'text-red-600 bg-red-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const getAlertSeverityColor = (severity: string) => {
    switch (severity) {
      case 'low': return 'text-blue-600 bg-blue-50';
      case 'medium': return 'text-yellow-600 bg-yellow-50';
      case 'high': return 'text-orange-600 bg-orange-50';
      case 'critical': return 'text-red-600 bg-red-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const getFilteredAgents = () => {
    return agents.filter(agent => {
      const matchesFilter = agentFilter === 'all' || agent.state === agentFilter;
      const matchesSearch = agent.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           agent.queue.toLowerCase().includes(searchTerm.toLowerCase());
      return matchesFilter && matchesSearch;
    });
  };

  const getFilteredQueues = () => {
    return queues.filter(queue => {
      const matchesFilter = queueFilter === 'all' || queue.status === queueFilter;
      const matchesSearch = queue.queueName.toLowerCase().includes(searchTerm.toLowerCase());
      return matchesFilter && matchesSearch;
    });
  };

  const getFilteredAlerts = () => {
    return alerts.filter(alert => {
      const matchesFilter = alertFilter === 'all' || alert.severity === alertFilter;
      const matchesSearch = alert.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           alert.message.toLowerCase().includes(searchTerm.toLowerCase());
      return matchesFilter && matchesSearch;
    });
  };

  return (
    <div className="bg-white rounded-lg shadow-lg h-full flex flex-col">
      {/* Header */}
      <div className="border-b px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-900">{t.title}</h2>
            <p className="text-sm text-gray-600">{t.subtitle}</p>
          </div>
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Clock className="h-4 w-4" />
              <span>{t.lastUpdate}: {lastUpdate}</span>
            </div>
            <button
              onClick={() => setIsPaused(!isPaused)}
              className={`p-2 rounded-lg ${isPaused ? 'text-gray-500' : 'text-green-600'}`}
            >
              {isPaused ? <Play className="h-4 w-4" /> : <Pause className="h-4 w-4" />}
            </button>
            <button
              onClick={() => setIsRealTimeEnabled(!isRealTimeEnabled)}
              className={`p-2 rounded-lg ${isRealTimeEnabled ? 'text-green-600' : 'text-gray-500'}`}
            >
              {isRealTimeEnabled ? <Bell className="h-4 w-4" /> : <BellOff className="h-4 w-4" />}
            </button>
            <button
              onClick={handleRefresh}
              className="p-2 text-gray-500 hover:text-gray-700"
              disabled={isLoading}
            >
              <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
            </button>
            <button
              onClick={handleExport}
              className="p-2 text-gray-500 hover:text-gray-700"
            >
              <Download className="h-4 w-4" />
            </button>
            <button
              onClick={() => setShowSettings(!showSettings)}
              className="p-2 text-gray-500 hover:text-gray-700"
            >
              <Settings className="h-4 w-4" />
            </button>
            <button
              onClick={() => setLanguage(language === 'ru' ? 'en' : 'ru')}
              className="p-2 text-gray-500 hover:text-gray-700"
            >
              <Globe className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mx-6 mt-4 bg-red-50 border border-red-200 rounded-lg p-4 flex items-center">
          <AlertTriangle className="h-5 w-5 text-red-600 mr-3" />
          <div>
            <p className="font-medium text-red-800">{t.error}</p>
            <p className="text-red-700 text-sm">{error}</p>
          </div>
        </div>
      )}

      {/* Navigation */}
      <div className="border-b">
        <nav className="flex px-6">
          <button
            onClick={() => setActiveView('overview')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'overview'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Monitor className="h-4 w-4 inline mr-2" />
            {t.sections.overview}
          </button>
          <button
            onClick={() => setActiveView('agents')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'agents'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Users className="h-4 w-4 inline mr-2" />
            {t.sections.agents}
          </button>
          <button
            onClick={() => setActiveView('queues')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'queues'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Phone className="h-4 w-4 inline mr-2" />
            {t.sections.queues}
          </button>
          <button
            onClick={() => setActiveView('alerts')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'alerts'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Bell className="h-4 w-4 inline mr-2" />
            {t.sections.alerts}
            {alerts.length > 0 && (
              <span className="ml-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                {alerts.length}
              </span>
            )}
          </button>
        </nav>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-6">
        {activeView === 'overview' && (
          <div className="space-y-6">
            {/* Key Metrics */}
            {metrics && (
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-4">{t.keyMetrics}</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {Object.entries(metrics).filter(([key]) => key !== 'timestamp').map(([key, metric]) => {
                    const Icon = getMetricIcon(key);
                    const TrendIcon = getTrendIcon(metric.trend);
                    return (
                      <div
                        key={key}
                        className={`p-4 rounded-lg border cursor-pointer transition-all ${getMetricColor(metric.status)} ${
                          expandedMetric === key ? 'ring-2 ring-blue-500' : ''
                        }`}
                        onClick={() => handleMetricClick(key)}
                      >
                        <div className="flex items-center justify-between mb-2">
                          <Icon className="h-5 w-5" />
                          <TrendIcon className="h-4 w-4" />
                        </div>
                        <h4 className="font-medium mb-1">
                          {t.metrics[key as keyof typeof t.metrics]}
                        </h4>
                        <div className="flex items-center gap-2">
                          <span className="text-2xl font-bold">
                            {metric.current}
                            {key.includes('Time') ? t.units.seconds : 
                             key.includes('Level') || key.includes('Satisfaction') ? t.units.percent : ''}
                          </span>
                          <span className="text-sm text-gray-600">
                            / {metric.target}
                          </span>
                        </div>
                        <div className="flex items-center justify-between mt-2 text-sm">
                          <span>{t.status[metric.status]}</span>
                          <span>{t.status[metric.trend]}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Drill-down Data */}
            {expandedMetric && drillDownData && (
              <div className="bg-gray-50 rounded-lg p-4">
                <div className="flex items-center justify-between mb-4">
                  <h4 className="font-medium">{t.drillDown}: {t.metrics[expandedMetric as keyof typeof t.metrics]}</h4>
                  <button
                    onClick={() => setExpandedMetric(null)}
                    className="text-gray-500 hover:text-gray-700"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
                  <div className="text-center">
                    <div className="text-xl font-bold text-gray-900">{drillDownData.summary.min}</div>
                    <div className="text-sm text-gray-600">Минимум</div>
                  </div>
                  <div className="text-center">
                    <div className="text-xl font-bold text-gray-900">{drillDownData.summary.max}</div>
                    <div className="text-sm text-gray-600">Максимум</div>
                  </div>
                  <div className="text-center">
                    <div className="text-xl font-bold text-gray-900">{drillDownData.summary.avg}</div>
                    <div className="text-sm text-gray-600">Среднее</div>
                  </div>
                  <div className="text-center">
                    <div className="text-xl font-bold text-gray-900">{drillDownData.summary.breaches}</div>
                    <div className="text-sm text-gray-600">Нарушения</div>
                  </div>
                </div>
                <div className="h-64 bg-white rounded border flex items-center justify-center">
                  <BarChart3 className="h-8 w-8 text-gray-400" />
                  <span className="ml-2 text-gray-500">График данных</span>
                </div>
              </div>
            )}

            {/* Quick Summary */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-gray-50 rounded-lg p-4">
                <h4 className="font-medium mb-2">{t.sections.agents}</h4>
                <div className="space-y-1">
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">Доступно:</span>
                    <span className="text-sm font-medium text-green-600">
                      {agents.filter(a => a.state === 'available').length}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">Занято:</span>
                    <span className="text-sm font-medium text-blue-600">
                      {agents.filter(a => a.state === 'busy').length}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">Перерыв:</span>
                    <span className="text-sm font-medium text-yellow-600">
                      {agents.filter(a => a.state === 'break').length}
                    </span>
                  </div>
                </div>
              </div>
              
              <div className="bg-gray-50 rounded-lg p-4">
                <h4 className="font-medium mb-2">{t.sections.queues}</h4>
                <div className="space-y-1">
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">Нормальные:</span>
                    <span className="text-sm font-medium text-green-600">
                      {queues.filter(q => q.status === 'normal').length}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">Предупреждения:</span>
                    <span className="text-sm font-medium text-yellow-600">
                      {queues.filter(q => q.status === 'warning').length}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">Критические:</span>
                    <span className="text-sm font-medium text-red-600">
                      {queues.filter(q => q.status === 'critical').length}
                    </span>
                  </div>
                </div>
              </div>
              
              <div className="bg-gray-50 rounded-lg p-4">
                <h4 className="font-medium mb-2">{t.sections.alerts}</h4>
                <div className="space-y-1">
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">Критические:</span>
                    <span className="text-sm font-medium text-red-600">
                      {alerts.filter(a => a.severity === 'critical').length}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">Высокие:</span>
                    <span className="text-sm font-medium text-orange-600">
                      {alerts.filter(a => a.severity === 'high').length}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-600">Всего:</span>
                    <span className="text-sm font-medium text-gray-900">
                      {alerts.length}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeView === 'agents' && (
          <div className="space-y-4">
            {/* Filters */}
            <div className="flex items-center gap-4">
              <div className="relative">
                <Search className="h-4 w-4 absolute left-3 top-3 text-gray-400" />
                <input
                  type="text"
                  placeholder={t.search}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <select
                value={agentFilter}
                onChange={(e) => setAgentFilter(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">Все состояния</option>
                <option value="available">{t.agentStates.available}</option>
                <option value="busy">{t.agentStates.busy}</option>
                <option value="break">{t.agentStates.break}</option>
                <option value="offline">{t.agentStates.offline}</option>
                <option value="after_call_work">{t.agentStates.after_call_work}</option>
              </select>
            </div>

            {/* Agent List */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {getFilteredAgents().map((agent) => {
                const StateIcon = getAgentStateIcon(agent.state);
                return (
                  <div
                    key={agent.id}
                    className={`p-4 rounded-lg border ${getAgentStateColor(agent.state)}`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <StateIcon className="h-5 w-5" />
                        <h4 className="font-medium">{agent.name}</h4>
                      </div>
                      <span className="text-xs px-2 py-1 rounded bg-white">
                        {t.agentStates[agent.state]}
                      </span>
                    </div>
                    <div className="space-y-1 text-sm">
                      <div className="flex justify-between">
                        <span className="text-gray-600">Очередь:</span>
                        <span className="font-medium">{agent.queue}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Звонков:</span>
                        <span className="font-medium">{agent.performance.callsHandled}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Среднее время:</span>
                        <span className="font-medium">{agent.performance.avgHandleTime}с</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Рейтинг:</span>
                        <span className="font-medium">{agent.performance.customerRating}</span>
                      </div>
                    </div>
                    <div className="mt-3 flex gap-2">
                      <button
                        onClick={() => handleAgentAction(agent.id, 'break')}
                        className="text-xs px-2 py-1 bg-yellow-100 text-yellow-800 rounded hover:bg-yellow-200"
                      >
                        Перерыв
                      </button>
                      <button
                        onClick={() => handleAgentAction(agent.id, 'available')}
                        className="text-xs px-2 py-1 bg-green-100 text-green-800 rounded hover:bg-green-200"
                      >
                        Доступен
                      </button>
                      <button
                        onClick={() => onAgentClick && onAgentClick(agent.id)}
                        className="text-xs px-2 py-1 bg-blue-100 text-blue-800 rounded hover:bg-blue-200"
                      >
                        Подробнее
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {activeView === 'queues' && (
          <div className="space-y-4">
            {/* Filters */}
            <div className="flex items-center gap-4">
              <div className="relative">
                <Search className="h-4 w-4 absolute left-3 top-3 text-gray-400" />
                <input
                  type="text"
                  placeholder={t.search}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <select
                value={queueFilter}
                onChange={(e) => setQueueFilter(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">Все статусы</option>
                <option value="normal">{t.queueStatus.normal}</option>
                <option value="warning">{t.queueStatus.warning}</option>
                <option value="critical">{t.queueStatus.critical}</option>
              </select>
            </div>

            {/* Queue List */}
            <div className="space-y-4">
              {getFilteredQueues().map((queue) => (
                <div
                  key={queue.queueId}
                  className={`p-4 rounded-lg border ${getQueueStatusColor(queue.status)}`}
                >
                  <div className="flex items-center justify-between mb-4">
                    <h4 className="font-medium">{queue.queueName}</h4>
                    <span className="text-xs px-2 py-1 rounded bg-white">
                      {t.queueStatus[queue.status]}
                    </span>
                  </div>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="text-center">
                      <div className="text-xl font-bold text-gray-900">{queue.waitingCalls}</div>
                      <div className="text-sm text-gray-600">Ожидают</div>
                    </div>
                    <div className="text-center">
                      <div className="text-xl font-bold text-gray-900">{queue.longestWait}с</div>
                      <div className="text-sm text-gray-600">Максимальное ожидание</div>
                    </div>
                    <div className="text-center">
                      <div className="text-xl font-bold text-gray-900">{queue.serviceLevel}%</div>
                      <div className="text-sm text-gray-600">Уровень сервиса</div>
                    </div>
                    <div className="text-center">
                      <div className="text-xl font-bold text-gray-900">{queue.agentsAvailable}/{queue.agentsLoggedIn}</div>
                      <div className="text-sm text-gray-600">Агенты</div>
                    </div>
                  </div>
                  <div className="mt-3 flex gap-2">
                    <button
                      onClick={() => onQueueClick && onQueueClick(queue.queueId)}
                      className="text-xs px-2 py-1 bg-blue-100 text-blue-800 rounded hover:bg-blue-200"
                    >
                      Подробнее
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {activeView === 'alerts' && (
          <div className="space-y-4">
            {/* Filters */}
            <div className="flex items-center gap-4">
              <div className="relative">
                <Search className="h-4 w-4 absolute left-3 top-3 text-gray-400" />
                <input
                  type="text"
                  placeholder={t.search}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <select
                value={alertFilter}
                onChange={(e) => setAlertFilter(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">Все уровни</option>
                <option value="critical">{t.alertSeverity.critical}</option>
                <option value="high">{t.alertSeverity.high}</option>
                <option value="medium">{t.alertSeverity.medium}</option>
                <option value="low">{t.alertSeverity.low}</option>
              </select>
            </div>

            {/* Alert List */}
            <div className="space-y-4">
              {getFilteredAlerts().map((alert) => (
                <div
                  key={alert.id}
                  className={`p-4 rounded-lg border ${getAlertSeverityColor(alert.severity)}`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <AlertTriangle className="h-5 w-5" />
                      <h4 className="font-medium">{alert.title}</h4>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs px-2 py-1 rounded bg-white">
                        {t.alertSeverity[alert.severity]}
                      </span>
                      <span className="text-xs px-2 py-1 rounded bg-white">
                        {t.alertTypes[alert.type]}
                      </span>
                    </div>
                  </div>
                  <p className="text-sm text-gray-600 mb-2">{alert.message}</p>
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-gray-500">
                      {new Date(alert.timestamp).toLocaleString()}
                    </span>
                    <div className="flex gap-2">
                      {!alert.acknowledged && (
                        <button
                          onClick={() => handleAlertAction(alert.id, 'acknowledge')}
                          className="text-xs px-2 py-1 bg-blue-100 text-blue-800 rounded hover:bg-blue-200"
                        >
                          {t.actions.acknowledge}
                        </button>
                      )}
                      <button
                        onClick={() => handleAlertAction(alert.id, 'resolve')}
                        className="text-xs px-2 py-1 bg-green-100 text-green-800 rounded hover:bg-green-200"
                      >
                        {t.actions.resolve}
                      </button>
                      <button
                        onClick={() => onAlertClick && onAlertClick(alert.id)}
                        className="text-xs px-2 py-1 bg-gray-100 text-gray-800 rounded hover:bg-gray-200"
                      >
                        {t.actions.details}
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default OperationalControlDashboard;