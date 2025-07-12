import React, { useState, useEffect } from 'react';
import { 
  Activity, 
  Users, 
  TrendingUp, 
  Clock,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Zap,
  ChevronRight,
  BarChart3,
  Eye
} from 'lucide-react';

// BDD: Mobile monitoring dashboard - Adapted from MobileDashboard
// Based on: 15-real-time-monitoring-operational-control.feature

interface MobileMetric {
  id: string;
  name: string;
  value: number;
  target: number;
  unit: string;
  status: 'excellent' | 'good' | 'warning' | 'critical';
  trend: 'up' | 'down' | 'stable';
  changePercent: number;
  icon: any;
}

interface MobileAgent {
  id: string;
  name: string;
  status: 'online' | 'offline' | 'break' | 'lunch' | 'training';
  currentCall: boolean;
  queue: string;
  callsHandled: number;
  lastActivity: Date;
}

const MobileMonitoringDashboard: React.FC = () => {
  const [metrics, setMetrics] = useState<MobileMetric[]>([]);
  const [agents, setAgents] = useState<MobileAgent[]>([]);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);

  // BDD: Key metrics optimized for mobile display
  useEffect(() => {
    const loadMobileMetrics = () => {
      const now = new Date();
      const mobileMetrics: MobileMetric[] = [
        {
          id: 'mobile_001',
          name: 'Агенты онлайн',
          value: 92.3,
          target: 85.0,
          unit: '%',
          status: 'excellent',
          trend: 'up',
          changePercent: 2.1,
          icon: Users
        },
        {
          id: 'mobile_002', 
          name: 'SLA',
          value: 94.7,
          target: 90.0,
          unit: '%',
          status: 'excellent',
          trend: 'stable',
          changePercent: 0.3,
          icon: CheckCircle
        },
        {
          id: 'mobile_003',
          name: 'AHT',
          value: 245,
          target: 300,
          unit: 'сек',
          status: 'good',
          trend: 'down',
          changePercent: -8.2,
          icon: Clock
        },
        {
          id: 'mobile_004',
          name: 'Отклонение',
          value: 7.4,
          target: 10.0,
          unit: '%',
          status: 'good',
          trend: 'down',
          changePercent: -1.8,
          icon: TrendingUp
        }
      ];

      setMetrics(mobileMetrics);
    };

    const loadMobileAgents = () => {
      const mockAgents: MobileAgent[] = [
        {
          id: 'agent_001',
          name: 'Анна П.',
          status: 'online',
          currentCall: true,
          queue: 'Техподдержка',
          callsHandled: 23,
          lastActivity: new Date(Date.now() - 2 * 60 * 1000)
        },
        {
          id: 'agent_002', 
          name: 'Михаил В.',
          status: 'online',
          currentCall: false,
          queue: 'Продажи',
          callsHandled: 18,
          lastActivity: new Date(Date.now() - 30 * 1000)
        },
        {
          id: 'agent_003',
          name: 'Елена К.',
          status: 'break',
          currentCall: false,
          queue: 'Техподдержка',
          callsHandled: 31,
          lastActivity: new Date(Date.now() - 5 * 60 * 1000)
        },
        {
          id: 'agent_004',
          name: 'Павел О.',
          status: 'lunch',
          currentCall: false,
          queue: 'Продажи',
          callsHandled: 12,
          lastActivity: new Date(Date.now() - 15 * 60 * 1000)
        }
      ];

      setAgents(mockAgents);
    };

    loadMobileMetrics();
    loadMobileAgents();
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
      case 'excellent': return 'text-green-600 bg-green-100';
      case 'good': return 'text-blue-600 bg-blue-100';
      case 'warning': return 'text-yellow-600 bg-yellow-100';
      case 'critical': return 'text-red-600 bg-red-100';
      default: return 'text-gray-600 bg-gray-100';
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
    if (unit === 'сек') return `${Math.round(value)}с`;
    return value.toFixed(1);
  };

  const getAgentStatusColor = (status: string) => {
    switch (status) {
      case 'online': return 'bg-green-500';
      case 'break': return 'bg-yellow-500';
      case 'lunch': return 'bg-orange-500';
      case 'training': return 'bg-blue-500';
      case 'offline': return 'bg-gray-500';
      default: return 'bg-gray-500';
    }
  };

  const getAgentStatusText = (status: string) => {
    switch (status) {
      case 'online': return 'В сети';
      case 'break': return 'Перерыв';
      case 'lunch': return 'Обед';
      case 'training': return 'Обучение';
      case 'offline': return 'Офлайн';
      default: return status;
    }
  };

  const agentStats = {
    total: agents.length,
    online: agents.filter(a => a.status === 'online').length,
    onCall: agents.filter(a => a.currentCall).length,
    break: agents.filter(a => a.status === 'break' || a.status === 'lunch').length
  };

  return (
    <div className="space-y-6 pb-4">
      {/* Header with Real-time Status */}
      <div className="bg-white rounded-lg shadow-sm p-4">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-semibold text-gray-900 flex items-center">
            <Activity className="h-5 w-5 mr-2 text-blue-600" />
            Оперативный контроль
          </h2>
          <div className={`flex items-center space-x-1 text-xs ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
            <div className={`w-2 h-2 rounded-full ${isUpdating ? 'bg-blue-500 animate-pulse' : 'bg-green-500'}`}></div>
            <span>{lastUpdate.toLocaleTimeString('ru-RU')}</span>
          </div>
        </div>
        
        {/* Agent Summary Bar */}
        <div className="grid grid-cols-4 gap-2 text-center">
          <div>
            <p className="text-lg font-bold text-blue-600">{agentStats.total}</p>
            <p className="text-xs text-gray-600">Всего</p>
          </div>
          <div>
            <p className="text-lg font-bold text-green-600">{agentStats.online}</p>
            <p className="text-xs text-gray-600">Онлайн</p>
          </div>
          <div>
            <p className="text-lg font-bold text-purple-600">{agentStats.onCall}</p>
            <p className="text-xs text-gray-600">На звонке</p>
          </div>
          <div>
            <p className="text-lg font-bold text-yellow-600">{agentStats.break}</p>
            <p className="text-xs text-gray-600">Перерыв</p>
          </div>
        </div>
      </div>

      {/* Key Metrics Grid - BDD: Optimized for mobile */}
      <div className="grid grid-cols-2 gap-3">
        {metrics.map((metric) => {
          const Icon = metric.icon;
          return (
            <div key={metric.id} className="bg-white rounded-lg shadow-sm p-4">
              <div className="flex items-center justify-between mb-2">
                <Icon className={`h-5 w-5 ${getStatusColor(metric.status)}`} />
                <div className="flex items-center space-x-1 text-xs">
                  <span>{getStatusIndicator(metric.status)}</span>
                  <span>{getTrendIcon(metric.trend)}</span>
                </div>
              </div>
              
              <div className="mb-2">
                <p className="text-xl font-bold text-gray-900">
                  {formatValue(metric.value, metric.unit)}
                </p>
                <p className="text-xs text-gray-600">{metric.name}</p>
              </div>

              <div className="w-full bg-gray-200 rounded-full h-1.5">
                <div 
                  className={`h-1.5 rounded-full transition-all duration-300 ${ 
                    metric.status === 'excellent' ? 'bg-green-500' :
                    metric.status === 'good' ? 'bg-blue-500' :
                    metric.status === 'warning' ? 'bg-yellow-500' : 'bg-red-500'
                  }`}
                  style={{ width: `${Math.min((metric.value / metric.target) * 100, 100)}%` }}
                ></div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Active Agents List - BDD: Mobile-optimized */}
      <div className="bg-white rounded-lg shadow-sm p-4">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-900">Активные агенты</h3>
          <button className="flex items-center text-sm text-blue-600">
            <Eye className="h-4 w-4 mr-1" />
            Все
          </button>
        </div>

        <div className="space-y-3">
          {agents.slice(0, 4).map((agent) => (
            <div key={agent.id} className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className={`w-3 h-3 rounded-full ${getAgentStatusColor(agent.status)}`}></div>
                <div>
                  <p className="font-medium text-gray-900 text-sm">{agent.name}</p>
                  <div className="flex items-center space-x-2 text-xs text-gray-500">
                    <span>{getAgentStatusText(agent.status)}</span>
                    <span>•</span>
                    <span>{agent.queue}</span>
                  </div>
                </div>
              </div>
              
              <div className="text-right">
                {agent.currentCall && (
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                    📞
                  </span>
                )}
                <p className="text-xs text-gray-500 mt-1">{agent.callsHandled} звонков</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Quick Actions - BDD: Mobile monitoring actions */}
      <div className="bg-white rounded-lg shadow-sm p-4">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Быстрые действия</h3>
        <div className="space-y-3">
          <button className="w-full flex items-center justify-between p-3 rounded-lg border border-gray-200 hover:bg-gray-50">
            <div className="flex items-center space-x-3">
              <div className="p-2 rounded-lg bg-blue-500">
                <BarChart3 className="h-4 w-4 text-white" />
              </div>
              <span className="font-medium text-gray-900 text-sm">Детальная статистика</span>
            </div>
            <ChevronRight className="h-4 w-4 text-gray-400" />
          </button>
          
          <button className="w-full flex items-center justify-between p-3 rounded-lg border border-gray-200 hover:bg-gray-50">
            <div className="flex items-center space-x-3">
              <div className="p-2 rounded-lg bg-green-500">
                <Activity className="h-4 w-4 text-white" />
              </div>
              <span className="font-medium text-gray-900 text-sm">Живой мониторинг</span>
            </div>
            <ChevronRight className="h-4 w-4 text-gray-400" />
          </button>

          <button className="w-full flex items-center justify-between p-3 rounded-lg border border-gray-200 hover:bg-gray-50">
            <div className="flex items-center space-x-3">
              <div className="p-2 rounded-lg bg-yellow-500">
                <AlertTriangle className="h-4 w-4 text-white" />
              </div>
              <span className="font-medium text-gray-900 text-sm">Настройки алертов</span>
            </div>
            <ChevronRight className="h-4 w-4 text-gray-400" />
          </button>
        </div>
      </div>

      {/* Status Summary Footer */}
      <div className="bg-gray-50 rounded-lg p-3">
        <div className="flex items-center justify-between text-sm">
          <div className="flex items-center space-x-4">
            <span className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
              Обновление каждые 30с
            </span>
          </div>
          <div className="flex items-center space-x-3 text-xs">
            <span>🟢 {metrics.filter(m => m.status === 'excellent').length}</span>
            <span>🔵 {metrics.filter(m => m.status === 'good').length}</span>
            <span>🟡 {metrics.filter(m => m.status === 'warning').length}</span>
            <span>🔴 {metrics.filter(m => m.status === 'critical').length}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MobileMonitoringDashboard;