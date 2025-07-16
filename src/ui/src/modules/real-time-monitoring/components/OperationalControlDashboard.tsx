import React, { useState, useEffect } from 'react';
import { Activity, Users, TrendingUp, Clock, AlertTriangle, CheckCircle, XCircle, Zap } from 'lucide-react';
import realOperationalService, { OperationalData, OperationalMetric, AgentStatus } from '../../../services/realOperationalService';

// BDD: Real-time operational dashboards - Adapted from EmployeeStatusManager
// Based on: 15-real-time-monitoring-operational-control.feature

const OperationalControlDashboard: React.FC = () => {
  const [operationalData, setOperationalData] = useState<OperationalData | null>(null);
  const [selectedQueue, setSelectedQueue] = useState<string>('all');
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [apiError, setApiError] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);

  // Load initial operational data
  useEffect(() => {
    loadOperationalData();
  }, []);
  
  const loadOperationalData = async () => {
    setApiError('');
    setIsConnecting(true);
    
    try {
      // Check API health first
      const isApiHealthy = await realOperationalService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      // Make real API call
      const result = await realOperationalService.getOperationalData();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Operational data loaded:', result.data);
        setOperationalData(result.data);
        setLastUpdate(new Date());
      } else {
        setApiError(result.error || 'Failed to load operational data');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Operational load error:', errorMessage);
    } finally {
      setIsLoading(false);
      setIsConnecting(false);
    }
  };

  // BDD: Real-time updates every 30 seconds
  useEffect(() => {
    const interval = setInterval(async () => {
      setIsUpdating(true);
      
      try {
        const result = await realOperationalService.refreshOperationalData();
        if (result.success && result.data) {
          setOperationalData(result.data);
        }
      } catch (error) {
        console.warn('[REAL COMPONENT] Auto-refresh failed:', error);
      }
      
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

  // Extract data from operationalData
  const metrics = operationalData?.metrics || [];
  const agents = operationalData?.agents || [];
  
  const filteredAgents = selectedQueue === 'all' 
    ? agents 
    : agents.filter(agent => agent.queue === selectedQueue);

  const agentStats = {
    total: operationalData?.totalAgents || 0,
    online: operationalData?.agentsOnline || 0,
    onCall: operationalData?.agentsOnCall || 0,
    break: operationalData?.agentsOnBreak || 0,
    training: operationalData?.agentsInTraining || 0
  };

  const uniqueQueues = [...new Set(agents.map(a => a.queue))];

  // Loading state
  if (isLoading) {
    return (
      <div className="p-6 space-y-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="animate-pulse">
            <div className="h-8 bg-gray-200 rounded w-1/3 mb-4"></div>
            <div className="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[1,2,3,4,5,6].map((i) => (
            <div key={i} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 animate-pulse">
              <div className="h-24 bg-gray-200 rounded"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* API Error Display */}
      {apiError && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center gap-2 text-red-800">
            <AlertTriangle className="h-5 w-5 text-red-500" />
            <div>
              <div className="font-medium">Operation Failed</div>
              <div className="text-sm">{apiError}</div>
            </div>
            <button
              onClick={loadOperationalData}
              className="ml-auto px-3 py-1 bg-red-100 text-red-700 rounded text-sm hover:bg-red-200"
            >
              Retry
            </button>
          </div>
        </div>
      )}
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
                  Активность: {Math.round((Date.now() - new Date(agent.lastActivity).getTime()) / (1000 * 60))}м назад
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