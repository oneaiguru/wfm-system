import React, { useState, useEffect } from 'react';
import { 
  Activity, 
  Users, 
  Phone, 
  Clock, 
  TrendingUp, 
  TrendingDown,
  AlertTriangle, 
  CheckCircle, 
  RefreshCw,
  Eye,
  BarChart3
} from 'lucide-react';
import realRealtimeService, { RealtimeData, RealtimeMetric, CallQueueMetrics } from '../../services/realRealtimeService';

// BDD: Real-time metrics display with live data updates
// Based on: realtime-metrics-monitoring.feature

const RealtimeMetrics: React.FC = () => {
  const [realtimeData, setRealtimeData] = useState<RealtimeData | null>(null);
  const [selectedMetric, setSelectedMetric] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [apiError, setApiError] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);

  // Load initial realtime data
  useEffect(() => {
    loadRealtimeData();
  }, []);

  const loadRealtimeData = async () => {
    setApiError('');
    setIsConnecting(true);
    
    try {
      // Check API health first
      const isApiHealthy = await realRealtimeService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      // Make real API call
      const result = await realRealtimeService.getRealtimeMetrics();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Realtime data loaded:', result.data);
        setRealtimeData(result.data);
        setLastUpdate(new Date());
      } else {
        setApiError(result.error || 'Failed to load realtime metrics');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Realtime load error:', errorMessage);
    } finally {
      setIsLoading(false);
      setIsConnecting(false);
    }
  };

  // 30-second real-time update pattern
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(async () => {
      setIsUpdating(true);
      
      try {
        const result = await realRealtimeService.refreshRealtimeMetrics();
        if (result.success && result.data) {
          setRealtimeData(result.data);
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
  }, [autoRefresh]);

  const getMetricStatusColor = (status: string) => {
    switch (status) {
      case 'normal': return 'text-green-600 bg-green-100 border-green-200';
      case 'warning': return 'text-yellow-600 bg-yellow-100 border-yellow-200';
      case 'critical': return 'text-red-600 bg-red-100 border-red-200';
      default: return 'text-gray-600 bg-gray-100 border-gray-200';
    }
  };

  const getMetricIcon = (metricName: string) => {
    if (metricName.toLowerCase().includes('agent')) return Users;
    if (metricName.toLowerCase().includes('call')) return Phone;
    if (metricName.toLowerCase().includes('time') || metricName.toLowerCase().includes('wait')) return Clock;
    if (metricName.toLowerCase().includes('service')) return CheckCircle;
    return Activity;
  };

  const getTrendIcon = (trend: string, changePercent: number) => {
    if (trend === 'up') {
      return <TrendingUp className={`h-4 w-4 ${changePercent > 0 ? 'text-green-500' : 'text-red-500'}`} />;
    } else if (trend === 'down') {
      return <TrendingDown className={`h-4 w-4 ${changePercent < 0 ? 'text-red-500' : 'text-green-500'}`} />;
    }
    return <div className="w-4 h-4 bg-gray-300 rounded-full" />;
  };

  const formatValue = (value: number, unit: string) => {
    if (unit === '%') return `${value.toFixed(1)}%`;
    if (unit === 'sec' || unit === 'seconds') return `${Math.round(value)}s`;
    if (unit === 'min' || unit === 'minutes') return `${Math.round(value)}m`;
    if (unit === 'calls') return value.toLocaleString();
    return value.toLocaleString();
  };

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
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1,2,3,4,5,6,7,8].map((i) => (
            <div key={i} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 animate-pulse">
              <div className="h-20 bg-gray-200 rounded"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  const metrics = realtimeData?.metrics || [];
  const queues = realtimeData?.queues || [];

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
              onClick={loadRealtimeData}
              className="ml-auto px-3 py-1 bg-red-100 text-red-700 rounded text-sm hover:bg-red-200"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <Activity className="h-6 w-6 mr-2 text-blue-600" />
              Real-time Metrics
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">📊</span>
              Live performance monitoring dashboard
            </p>
          </div>
          
          <div className="text-right">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => setAutoRefresh(!autoRefresh)}
                className={`flex items-center space-x-2 px-3 py-1 rounded text-sm transition-colors ${
                  autoRefresh ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
                }`}
              >
                <RefreshCw className={`h-4 w-4 ${isUpdating ? 'animate-spin' : ''}`} />
                <span>{autoRefresh ? 'Auto-refresh ON' : 'Auto-refresh OFF'}</span>
              </button>
              <div className={`flex items-center space-x-2 text-sm ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
                <div className={`w-2 h-2 rounded-full ${isUpdating ? 'bg-blue-500 animate-pulse' : 'bg-green-500'}`}></div>
                <span>Updated: {lastUpdate.toLocaleTimeString()}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {metrics.map((metric) => {
          const Icon = getMetricIcon(metric.name);
          return (
            <div 
              key={metric.id} 
              className={`bg-white rounded-lg shadow-sm border-2 p-6 cursor-pointer transition-all hover:shadow-lg ${getMetricStatusColor(metric.status)}`}
              onClick={() => setSelectedMetric(metric.id)}
            >
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-2">
                  <Icon className="h-6 w-6" />
                  <h3 className="font-semibold text-gray-900">{metric.name}</h3>
                </div>
                {getTrendIcon(metric.trend, metric.changePercent)}
              </div>
              
              <div className="mb-2">
                <div className="flex items-baseline space-x-2">
                  <span className="text-3xl font-bold text-gray-900">
                    {formatValue(metric.value, metric.unit)}
                  </span>
                  {metric.threshold && (
                    <span className="text-sm text-gray-600">
                      / {formatValue(metric.threshold, metric.unit)}
                    </span>
                  )}
                </div>
              </div>

              {metric.threshold && (
                <div className="mb-3">
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full transition-all duration-300 ${
                        metric.status === 'normal' ? 'bg-green-500' :
                        metric.status === 'warning' ? 'bg-yellow-500' : 'bg-red-500'
                      }`}
                      style={{ width: `${Math.min((metric.value / metric.threshold) * 100, 100)}%` }}
                    ></div>
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between text-sm">
                <span className={`font-medium ${
                  metric.changePercent > 0 ? 'text-green-600' : 
                  metric.changePercent < 0 ? 'text-red-600' : 'text-gray-600'
                }`}>
                  {metric.changePercent > 0 ? '+' : ''}{metric.changePercent.toFixed(1)}%
                </span>
                <span className="text-gray-500">
                  {new Date(metric.timestamp).toLocaleTimeString()}
                </span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Queue Metrics */}
      {queues.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center">
              <Phone className="h-5 w-5 mr-2" />
              Queue Performance
            </h3>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Queue</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Waiting</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Avg Wait</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Longest Wait</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Service Level</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Agents</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {queues.map((queue) => (
                  <tr key={queue.queueId} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="font-medium text-gray-900">{queue.queueName}</div>
                      <div className="text-sm text-gray-500">ID: {queue.queueId}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                        queue.callsWaiting === 0 ? 'bg-green-100 text-green-800' :
                        queue.callsWaiting < 5 ? 'bg-yellow-100 text-yellow-800' :
                        'bg-red-100 text-red-800'
                      }`}>
                        {queue.callsWaiting} calls
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {Math.round(queue.avgWaitTime)}s
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {Math.round(queue.longestWaitTime)}s
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="w-16 bg-gray-200 rounded-full h-2 mr-2">
                          <div 
                            className={`h-2 rounded-full ${
                              queue.serviceLevel >= 80 ? 'bg-green-500' :
                              queue.serviceLevel >= 60 ? 'bg-yellow-500' : 'bg-red-500'
                            }`}
                            style={{ width: `${queue.serviceLevel}%` }}
                          ></div>
                        </div>
                        <span className="text-sm text-gray-900">{queue.serviceLevel.toFixed(1)}%</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {queue.agentsAvailable}/{queue.agentsLoggedIn}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <button className="text-blue-600 hover:text-blue-800">
                        <Eye className="h-4 w-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Summary Stats */}
      {realtimeData && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center">
              <Phone className="h-6 w-6 text-blue-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-600">Total Calls Today</p>
                <p className="text-2xl font-bold text-blue-600">{realtimeData.totalCallsToday.toLocaleString()}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center">
              <Users className="h-6 w-6 text-green-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-600">Agents Online</p>
                <p className="text-2xl font-bold text-green-600">{realtimeData.totalAgentsOnline}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center">
              <CheckCircle className="h-6 w-6 text-purple-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-600">Overall Service Level</p>
                <p className="text-2xl font-bold text-purple-600">{realtimeData.overallServiceLevel.toFixed(1)}%</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center">
              <BarChart3 className="h-6 w-6 text-orange-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-600">System Load</p>
                <p className="text-2xl font-bold text-orange-600">{realtimeData.systemLoad.toFixed(1)}%</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Real-time Status Bar */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
              <span className="text-sm text-gray-600">Real-time monitoring active</span>
            </div>
            <div className="text-sm text-gray-500">
              Refresh rate: {realtimeData?.refreshRate || 30} seconds
            </div>
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            <span>🟢 {metrics.filter(m => m.status === 'normal').length} Normal</span>
            <span>🟡 {metrics.filter(m => m.status === 'warning').length} Warning</span>
            <span>🔴 {metrics.filter(m => m.status === 'critical').length} Critical</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RealtimeMetrics;