import React, { useState, useEffect } from 'react';
import { Activity, Users, TrendingUp, Clock, AlertTriangle, CheckCircle, XCircle, Zap } from 'lucide-react';

// BDD: Real-time operational dashboards - Adapted from EmployeeStatusManager
// Based on: 15-real-time-monitoring-operational-control.feature

interface OperationalMetric {
  id: string;
  name: string;
  value: number;
  target: number;
  unit: string;
  status: 'excellent' | 'good' | 'warning' | 'critical';
  trend: 'up' | 'down' | 'stable';
  changePercent: number;
  lastUpdated: Date;
  description: string;
}

interface AgentStatus {
  id: string;
  name: string;
  status: 'online' | 'offline' | 'break' | 'lunch' | 'training';
  currentCall: boolean;
  queue: string;
  loginTime: string;
  callsHandled: number;
  avgHandleTime: number;
  lastActivity: Date;
}

const OperationalControlDashboard: React.FC = () => {
  const [metrics, setMetrics] = useState<OperationalMetric[]>([]);
  const [agents, setAgents] = useState<AgentStatus[]>([]);
  const [selectedQueue, setSelectedQueue] = useState<string>('all');
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);

  // BDD: Six key real-time metrics with traffic light indicators
  useEffect(() => {
    const loadMetrics = () => {
      const now = new Date();
      const mockMetrics: OperationalMetric[] = [
        {
          id: 'metric_001',
          name: 'Операторы онлайн',
          value: 92.3,
          target: 85.0,
          unit: '%',
          status: 'excellent',
          trend: 'up',
          changePercent: 2.1,
          lastUpdated: now,
          description: 'Процент операторов, находящихся в сети'
        },
        {
          id: 'metric_002',
          name: 'Отклонение нагрузки',
          value: 7.4,
          target: 10.0,
          unit: '%',
          status: 'good',
          trend: 'down',
          changePercent: -1.8,
          lastUpdated: now,
          description: 'Отклонение фактической нагрузки от прогноза'
        },
        {
          id: 'metric_003',
          name: 'Потребность в операторах',
          value: 47,
          target: 50,
          unit: 'agents',
          status: 'warning',
          trend: 'up',
          changePercent: 4.4,
          lastUpdated: now,
          description: 'Количество операторов, необходимых для текущей нагрузки'
        },
        {
          id: 'metric_004',
          name: 'Выполнение SLA',
          value: 94.7,
          target: 90.0,
          unit: '%',
          status: 'excellent',
          trend: 'stable',
          changePercent: 0.3,
          lastUpdated: now,
          description: 'Процент звонков, отвеченных в соответствии с SLA'
        },
        {
          id: 'metric_005',
          name: 'Коэффициент ACD',
          value: 89.2,
          target: 85.0,
          unit: '%',
          status: 'excellent',
          trend: 'up',
          changePercent: 1.5,
          lastUpdated: now,
          description: 'Процент звонков, обработанных автоматическим распределителем'
        },
        {
          id: 'metric_006',
          name: 'Тренд AHT',
          value: 245,
          target: 300,
          unit: 'sec',
          status: 'good',
          trend: 'down',
          changePercent: -8.2,
          lastUpdated: now,
          description: 'Среднее время обработки звонка'
        }
      ];

      setMetrics(mockMetrics);
    };

    const loadAgents = () => {
      const mockAgents: AgentStatus[] = [
        {
          id: 'agent_001',
          name: 'Анна Петрова',
          status: 'online',
          currentCall: true,
          queue: 'Техподдержка',
          loginTime: '09:00',
          callsHandled: 23,
          avgHandleTime: 245,
          lastActivity: new Date(Date.now() - 2 * 60 * 1000)
        },
        {
          id: 'agent_002',
          name: 'Михаил Волков',
          status: 'online',
          currentCall: false,
          queue: 'Продажи',
          loginTime: '09:15',
          callsHandled: 18,
          avgHandleTime: 290,
          lastActivity: new Date(Date.now() - 30 * 1000)
        },
        {
          id: 'agent_003',
          name: 'Елена Козлова',
          status: 'break',
          currentCall: false,
          queue: 'Техподдержка',
          loginTime: '08:45',
          callsHandled: 31,
          avgHandleTime: 198,
          lastActivity: new Date(Date.now() - 5 * 60 * 1000)
        },
        {
          id: 'agent_004',
          name: 'Павел Орлов',
          status: 'lunch',
          currentCall: false,
          queue: 'Продажи',
          loginTime: '10:00',
          callsHandled: 12,
          avgHandleTime: 312,
          lastActivity: new Date(Date.now() - 15 * 60 * 1000)
        },
        {
          id: 'agent_005',
          name: 'София Иванова',
          status: 'training',
          currentCall: false,
          queue: 'Обучение',
          loginTime: '09:30',
          callsHandled: 0,
          avgHandleTime: 0,
          lastActivity: new Date(Date.now() - 45 * 60 * 1000)
        }
      ];

      setAgents(mockAgents);
    };

    loadMetrics();
    loadAgents();
  }, []);

  // BDD: Real-time updates every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      setIsUpdating(true);
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return 'bg-green-100 text-green-800 border-green-200';
      case 'good': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'warning': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'critical': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusIndicator = (status: string) => {
    switch (status) {
      case 'excellent': return '🟢';
      case 'good': return '🔵';
      case 'warning': return '🟡';
      case 'critical': return '🔴';
      default: return '⚪';
    }
  };

  const getAgentStatusColor = (status: string) => {
    switch (status) {
      case 'online': return 'bg-green-100 text-green-800';
      case 'break': return 'bg-yellow-100 text-yellow-800';
      case 'lunch': return 'bg-orange-100 text-orange-800';
      case 'training': return 'bg-blue-100 text-blue-800';
      case 'offline': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getAgentStatusText = (status: string) => {
    switch (status) {
      case 'online': return 'В сети';
      case 'break': return 'Перерыв';
      case 'lunch': return 'Обед';
      case 'training': return 'Обучение';
      case 'offline': return 'Не в сети';
      default: return status;
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return '↗️';
      case 'down': return '↘️';
      case 'stable': return '➡️';
      default: return '➡️';
    }
  };

  const formatValue = (value: number, unit: string) => {
    if (unit === '%') return `${value.toFixed(1)}%`;
    if (unit === 'sec') return `${Math.round(value)}с`;
    if (unit === 'agents') return value.toString();
    return value.toFixed(1);
  };

  const filteredAgents = selectedQueue === 'all' 
    ? agents 
    : agents.filter(agent => agent.queue === selectedQueue);

  const agentStats = {
    total: agents.length,
    online: agents.filter(a => a.status === 'online').length,
    onCall: agents.filter(a => a.currentCall).length,
    break: agents.filter(a => a.status === 'break' || a.status === 'lunch').length,
    training: agents.filter(a => a.status === 'training').length
  };

  const uniqueQueues = [...new Set(agents.map(a => a.queue))];

  return (
    <div className="p-6 space-y-6">
      {/* Header - BDD: Main monitoring dashboard */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <Activity className="h-6 w-6 mr-2 text-blue-600" />
              Центр оперативного управления
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">📊</span>
              Мониторинг в реальном времени - ООО "ТехноСервис"
            </p>
          </div>
          
          <div className="text-right">
            <div className={`flex items-center space-x-2 text-sm ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
              <div className={`w-2 h-2 rounded-full ${isUpdating ? 'bg-blue-500 animate-pulse' : 'bg-green-500'}`}></div>
              <span>Обновлено: {lastUpdate.toLocaleTimeString('ru-RU')}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Key Metrics Grid - BDD: Six key real-time metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {metrics.map((metric) => (
          <div key={metric.id} className={`bg-white rounded-lg shadow-sm border-2 p-6 ${getStatusColor(metric.status)}`}>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-2">
                <span className="text-2xl">{getStatusIndicator(metric.status)}</span>
                <h3 className="font-semibold text-gray-900">{metric.name}</h3>
              </div>
              <div className="flex items-center space-x-1 text-sm text-gray-600">
                <span>{getTrendIcon(metric.trend)}</span>
                <span>{Math.abs(metric.changePercent).toFixed(1)}%</span>
              </div>
            </div>
            
            <div className="mb-2">
              <div className="flex items-baseline space-x-2">
                <span className="text-3xl font-bold text-gray-900">
                  {formatValue(metric.value, metric.unit)}
                </span>
                <span className="text-sm text-gray-600">
                  / {formatValue(metric.target, metric.unit)}
                </span>
              </div>
            </div>

            <div className="mb-3">
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div 
                  className={`h-2 rounded-full transition-all duration-300 ${
                    metric.status === 'excellent' ? 'bg-green-500' :
                    metric.status === 'good' ? 'bg-blue-500' :
                    metric.status === 'warning' ? 'bg-yellow-500' : 'bg-red-500'
                  }`}
                  style={{ width: `${Math.min((metric.value / metric.target) * 100, 100)}%` }}
                ></div>
              </div>
            </div>

            <p className="text-xs text-gray-600">{metric.description}</p>
          </div>
        ))}
      </div>

      {/* Agent Status Overview - BDD: Agent monitoring */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center">
            <Users className="h-6 w-6 text-blue-600" />
            <div className="ml-3">
              <p className="text-sm font-medium text-gray-600">Всего агентов</p>
              <p className="text-2xl font-bold text-blue-600">{agentStats.total}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center">
            <CheckCircle className="h-6 w-6 text-green-600" />
            <div className="ml-3">
              <p className="text-sm font-medium text-gray-600">В сети</p>
              <p className="text-2xl font-bold text-green-600">{agentStats.online}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center">
            <Zap className="h-6 w-6 text-purple-600" />
            <div className="ml-3">
              <p className="text-sm font-medium text-gray-600">На звонке</p>
              <p className="text-2xl font-bold text-purple-600">{agentStats.onCall}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center">
            <Clock className="h-6 w-6 text-yellow-600" />
            <div className="ml-3">
              <p className="text-sm font-medium text-gray-600">Перерыв</p>
              <p className="text-2xl font-bold text-yellow-600">{agentStats.break}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center">
            <TrendingUp className="h-6 w-6 text-blue-600" />
            <div className="ml-3">
              <p className="text-sm font-medium text-gray-600">Обучение</p>
              <p className="text-2xl font-bold text-blue-600">{agentStats.training}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Agent List with Queue Filter - BDD: Individual agent tracking */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900">Статус агентов</h3>
            <select
              value={selectedQueue}
              onChange={(e) => setSelectedQueue(e.target.value)}
              className="px-3 py-1 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">Все очереди</option>
              {uniqueQueues.map(queue => (
                <option key={queue} value={queue}>{queue}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="divide-y divide-gray-200">
          {filteredAgents.map((agent) => (
            <div key={agent.id} className="p-4 hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <div className="flex-shrink-0">
                    <div className={`w-3 h-3 rounded-full ${
                      agent.status === 'online' ? 'bg-green-500' :
                      agent.status === 'break' || agent.status === 'lunch' ? 'bg-yellow-500' :
                      agent.status === 'training' ? 'bg-blue-500' : 'bg-gray-500'
                    }`}></div>
                  </div>
                  
                  <div>
                    <div className="flex items-center space-x-3">
                      <h4 className="font-medium text-gray-900">{agent.name}</h4>
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getAgentStatusColor(agent.status)}`}>
                        {getAgentStatusText(agent.status)}
                      </span>
                      {agent.currentCall && (
                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                          📞 На звонке
                        </span>
                      )}
                    </div>
                    <div className="flex items-center space-x-4 text-sm text-gray-500 mt-1">
                      <span>Очередь: {agent.queue}</span>
                      <span>Вход: {agent.loginTime}</span>
                      <span>Звонков: {agent.callsHandled}</span>
                      {agent.avgHandleTime > 0 && (
                        <span>AHT: {agent.avgHandleTime}с</span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="text-right text-sm text-gray-500">
                  Активность: {Math.round((Date.now() - agent.lastActivity.getTime()) / (1000 * 60))}м назад
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Real-time Status Bar - BDD: Live monitoring indicator */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
              <span className="text-sm text-gray-600">Мониторинг в реальном времени</span>
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
    </div>
  );
};

export default OperationalControlDashboard;