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
  BarChart3,
  Server,
  Database,
  Wifi
} from 'lucide-react';
import realOperationalService, { OperationalData, OperationalMetric, AgentStatus } from '../../services/realOperationalService';

// Performance Component 1: Real-time System Metrics using GET /api/v1/monitoring/operational
// This component displays live system performance metrics with real-time updates

const RealtimeMetrics: React.FC = () => {
  const [operationalData, setOperationalData] = useState<OperationalData | null>(null);
  const [selectedMetric, setSelectedMetric] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [apiError, setApiError] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);

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

      // Make real API call to GET /api/v1/monitoring/operational
      const result = await realOperationalService.getOperationalData();
      
      if (result.success && result.data) {
        console.log('[PERFORMANCE COMPONENT] Operational data loaded:', result.data);
        setOperationalData(result.data);
        setLastUpdate(new Date());
      } else {
        setApiError(result.error || 'Failed to load operational metrics');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[PERFORMANCE COMPONENT] Operational load error:', errorMessage);
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
        const result = await realOperationalService.refreshOperationalData();
        if (result.success && result.data) {
          setOperationalData(result.data);
        }
      } catch (error) {
        console.warn('[PERFORMANCE COMPONENT] Auto-refresh failed:', error);
      }
      
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 30000);

    return () => clearInterval(interval);
  }, [autoRefresh]);

  const getStatusColor = (status: string) => {
    switch (status?.toLowerCase()) {
      case 'healthy':
      case 'good':
      case 'excellent':
      case 'normal':
        return 'text-green-600 bg-green-100 border-green-200';
      case 'warning':
      case 'degraded':
        return 'text-yellow-600 bg-yellow-100 border-yellow-200';
      case 'critical':
      case 'unhealthy':
      case 'error':
        return 'text-red-600 bg-red-100 border-red-200';
      default: 
        return 'text-gray-600 bg-gray-100 border-gray-200';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status?.toLowerCase()) {
      case 'healthy':
      case 'good':
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'warning':
      case 'degraded':
        return <AlertTriangle className="h-5 w-5 text-yellow-500" />;
      case 'critical':
      case 'unhealthy':
        return <AlertTriangle className="h-5 w-5 text-red-500" />;
      default:
        return <Activity className="h-5 w-5 text-gray-500" />;
    }
  };

  const formatResponseTime = (ms: number) => {
    if (ms < 1000) return `${ms}ms`;
    return `${(ms / 1000).toFixed(1)}s`;
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
          {[1,2,3,4,5,6].map((i) => (
            <div key={i} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 animate-pulse">
              <div className="h-20 bg-gray-200 rounded"></div>
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
              <div className="font-medium">Connection Failed</div>
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

      {/* Header */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <Activity className="h-6 w-6 mr-2 text-blue-600" />
              Real-time Performance Metrics
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">📊</span>
              Live system performance monitoring dashboard
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

      {/* System Health Overview */}
      {operationalData && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className={`bg-white rounded-lg shadow-sm border-2 p-6 ${getStatusColor(operationalData.system_health)}`}>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-2">
                <Server className="h-6 w-6" />
                <h3 className="font-semibold text-gray-900">System Health</h3>
              </div>
              {getStatusIcon(operationalData.system_health)}
            </div>
            <div className="text-2xl font-bold capitalize">{operationalData.system_health}</div>
            <div className="text-sm text-gray-600 mt-1">Overall system status</div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-2">
                <Users className="h-6 w-6 text-blue-600" />
                <h3 className="font-semibold text-gray-900">Active Agents</h3>
              </div>
              <TrendingUp className="h-4 w-4 text-green-500" />
            </div>
            <div className="text-2xl font-bold text-blue-600">{operationalData.active_agents}</div>
            <div className="text-sm text-gray-600 mt-1">Currently online</div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-2">
                <Phone className="h-6 w-6 text-green-600" />
                <h3 className="font-semibold text-gray-900">Total Requests</h3>
              </div>
              <TrendingUp className="h-4 w-4 text-green-500" />
            </div>
            <div className="text-2xl font-bold text-green-600">{operationalData.total_requests.toLocaleString()}</div>
            <div className="text-sm text-gray-600 mt-1">Processed today</div>
          </div>

          <div className={`bg-white rounded-lg shadow-sm border-2 p-6 ${getStatusColor(operationalData.database_status)}`}>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-2">
                <Database className="h-6 w-6" />
                <h3 className="font-semibold text-gray-900">Database</h3>
              </div>
              {getStatusIcon(operationalData.database_status)}
            </div>
            <div className="text-2xl font-bold capitalize">{operationalData.database_status}</div>
            <div className="text-sm text-gray-600 mt-1">Connection status</div>
          </div>
        </div>
      )}

      {/* API Response Time */}
      {operationalData && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-2">
              <Wifi className="h-6 w-6 text-purple-600" />
              <h3 className="text-lg font-semibold text-gray-900">API Response Time</h3>
            </div>
            <div className={`px-3 py-1 rounded text-sm ${
              operationalData.api_response_time < 200 ? 'bg-green-100 text-green-700' :
              operationalData.api_response_time < 500 ? 'bg-yellow-100 text-yellow-700' :
              'bg-red-100 text-red-700'
            }`}>
              {formatResponseTime(operationalData.api_response_time)}
            </div>
          </div>
          
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div 
              className={`h-3 rounded-full transition-all duration-300 ${
                operationalData.api_response_time < 200 ? 'bg-green-500' :
                operationalData.api_response_time < 500 ? 'bg-yellow-500' : 'bg-red-500'
              }`}
              style={{ width: `${Math.min((operationalData.api_response_time / 1000) * 100, 100)}%` }}
            ></div>
          </div>
        </div>
      )}

      {/* Component Status */}
      {operationalData?.components && operationalData.components.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center">
              <BarChart3 className="h-5 w-5 mr-2" />
              Component Status
            </h3>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Component</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Response Time</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Check</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {operationalData.components.map((component, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="font-medium text-gray-900">{component.component}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center space-x-2">
                        {getStatusIcon(component.status)}
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium capitalize ${getStatusColor(component.status)}`}>
                          {component.status}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatResponseTime(component.response_time_ms)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {new Date(component.last_check).toLocaleTimeString()}
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

      {/* Real-time Status Bar */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
              <span className="text-sm text-gray-600">Real-time monitoring active</span>
            </div>
            <div className="text-sm text-gray-500">
              Refresh rate: 30 seconds
            </div>
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            {operationalData?.components && (
              <>
                <span>🟢 {operationalData.components.filter(c => c.status.toLowerCase() === 'healthy').length} Healthy</span>
                <span>🟡 {operationalData.components.filter(c => c.status.toLowerCase() === 'warning').length} Warning</span>
                <span>🔴 {operationalData.components.filter(c => c.status.toLowerCase() === 'critical').length} Critical</span>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default RealtimeMetrics;