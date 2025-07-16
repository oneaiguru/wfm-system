import React, { useState, useEffect } from 'react';
import realReportsService, { KPIDashboard, RealtimeMetrics, KPIMetric } from '../../../../services/realReportsService';

export interface AnalyticsDashboardProps {
  refreshInterval?: number; // in seconds, default 30
}

const AnalyticsDashboard: React.FC<AnalyticsDashboardProps> = ({ refreshInterval = 30 }) => {
  const [kpiDashboard, setKpiDashboard] = useState<KPIDashboard | null>(null);
  const [realtimeMetrics, setRealtimeMetrics] = useState<RealtimeMetrics | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [apiHealthy, setApiHealthy] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());

  useEffect(() => {
    loadDashboardData();
    
    // Set up auto-refresh
    const refreshTimer = setInterval(() => {
      loadDashboardData();
    }, refreshInterval * 1000);

    return () => clearInterval(refreshTimer);
  }, [refreshInterval]);

  const loadDashboardData = async () => {
    setIsLoading(true);
    setApiError('');

    try {
      // Check API health first
      const isHealthy = await realReportsService.checkApiHealth();
      setApiHealthy(isHealthy);

      if (!isHealthy) {
        throw new Error('Analytics API server is not available. Please try again later.');
      }

      // Load KPI Dashboard and Real-time Metrics in parallel
      const [kpiResult, metricsResult] = await Promise.all([
        realReportsService.getKPIDashboard(),
        realReportsService.getRealtimeMetrics()
      ]);

      if (kpiResult.success && kpiResult.data) {
        setKpiDashboard(kpiResult.data);
        console.log('[REAL ANALYTICS DASHBOARD] Loaded KPI data:', kpiResult.data);
      } else {
        console.warn('[REAL ANALYTICS DASHBOARD] Failed to load KPI data:', kpiResult.error);
      }

      if (metricsResult.success && metricsResult.data) {
        setRealtimeMetrics(metricsResult.data);
        console.log('[REAL ANALYTICS DASHBOARD] Loaded real-time metrics:', metricsResult.data);
      } else {
        console.warn('[REAL ANALYTICS DASHBOARD] Failed to load real-time metrics:', metricsResult.error);
      }

      // If both failed, show error
      if (!kpiResult.success && !metricsResult.success) {
        setApiError('Failed to load dashboard data');
      }

      setLastRefresh(new Date());

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL ANALYTICS DASHBOARD] Error loading data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const renderKPIMetric = (label: string, metric: KPIMetric | undefined) => {
    if (!metric) {
      return (
        <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
          <div className="text-sm font-medium text-gray-900">{label}</div>
          <div className="text-2xl font-bold text-gray-400 mt-1">--</div>
          <div className="text-xs text-gray-400 mt-1">No data</div>
        </div>
      );
    }

    const getStatusColor = (status: string) => {
      switch (status) {
        case 'on_target': return 'text-green-600';
        case 'warning': return 'text-yellow-600';
        case 'critical': return 'text-red-600';
        default: return 'text-gray-600';
      }
    };

    const getTrendIcon = (trend: string) => {
      switch (trend) {
        case 'up': return '📈';
        case 'down': return '📉';
        case 'stable': return '➡️';
        default: return '';
      }
    };

    return (
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div className="flex items-center justify-between">
          <div className="text-sm font-medium text-gray-900">{label}</div>
          <div className="flex items-center space-x-1">
            <span className="text-xs">{getTrendIcon(metric.trend)}</span>
            <div className={`w-2 h-2 rounded-full ${
              metric.status === 'on_target' ? 'bg-green-500' :
              metric.status === 'warning' ? 'bg-yellow-500' :
              'bg-red-500'
            }`}></div>
          </div>
        </div>
        <div className={`text-2xl font-bold mt-1 ${getStatusColor(metric.status)}`}>
          {metric.current_value.toFixed(metric.unit === '%' ? 1 : 0)}{metric.unit}
        </div>
        <div className="text-xs text-gray-500 mt-1">
          Target: {metric.target_value.toFixed(metric.unit === '%' ? 1 : 0)}{metric.unit}
        </div>
        <div className="text-xs text-gray-400 mt-1">
          Updated: {new Date(metric.last_updated).toLocaleTimeString()}
        </div>
      </div>
    );
  };

  const renderRealtimeSection = () => {
    if (!realtimeMetrics) {
      return (
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Real-time Operations</h3>
          <div className="text-gray-500">No real-time data available</div>
        </div>
      );
    }

    return (
      <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-medium text-gray-900">Real-time Operations</h3>
          <div className="text-xs text-gray-500">
            Updated: {new Date(realtimeMetrics.timestamp).toLocaleTimeString()}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="p-4 bg-blue-50 rounded-lg">
            <div className="text-sm text-blue-700">Current Staffing</div>
            <div className="text-2xl font-bold text-blue-900">
              {realtimeMetrics.current_metrics.staffing_percentage.toFixed(1)}%
            </div>
            <div className="text-xs text-blue-600">
              {realtimeMetrics.current_metrics.active_agents} agents active
            </div>
          </div>

          <div className="p-4 bg-green-50 rounded-lg">
            <div className="text-sm text-green-700">Service Level</div>
            <div className="text-2xl font-bold text-green-900">
              {realtimeMetrics.current_metrics.service_level_80_20.toFixed(1)}%
            </div>
            <div className="text-xs text-green-600">80/20 target</div>
          </div>

          <div className="p-4 bg-purple-50 rounded-lg">
            <div className="text-sm text-purple-700">Queue Time</div>
            <div className="text-2xl font-bold text-purple-900">
              {realtimeMetrics.current_metrics.average_queue_time.toFixed(1)}m
            </div>
            <div className="text-xs text-purple-600">
              {realtimeMetrics.current_metrics.calls_in_queue} calls waiting
            </div>
          </div>
        </div>

        {/* Active Alerts */}
        {realtimeMetrics.active_alerts && realtimeMetrics.active_alerts.length > 0 && (
          <div className="border-t border-gray-200 pt-4">
            <h4 className="text-sm font-medium text-gray-900 mb-2">Active Alerts</h4>
            <div className="space-y-2">
              {realtimeMetrics.active_alerts.map((alert, index) => (
                <div key={index} className={`p-2 rounded text-sm ${
                  alert.severity === 'emergency' ? 'bg-red-100 text-red-800' :
                  alert.severity === 'critical' ? 'bg-red-50 text-red-700' :
                  alert.severity === 'warning' ? 'bg-yellow-50 text-yellow-700' :
                  'bg-blue-50 text-blue-700'
                }`}>
                  <div className="font-medium">{alert.type}</div>
                  <div className="text-xs">{alert.condition}</div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Analytics Dashboard</h1>
              <p className="text-gray-600 mt-1">Real-time WFM performance metrics and KPIs</p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className={`w-2 h-2 rounded-full ${apiHealthy ? 'bg-green-500' : 'bg-red-500'} animate-pulse`}></div>
                <span className="text-sm text-gray-600">
                  {apiHealthy ? 'Live Data' : 'API Offline'}
                </span>
              </div>
              <div className="text-sm text-gray-500">
                Last refresh: {lastRefresh.toLocaleTimeString()}
              </div>
              <button
                onClick={loadDashboardData}
                disabled={isLoading}
                className="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 disabled:opacity-50 transition-colors"
              >
                {isLoading ? 'Refreshing...' : 'Refresh'}
              </button>
            </div>
          </div>
        </div>

        {/* API Error Display */}
        {apiError && (
          <div className="mb-6 px-6 py-3 bg-red-50 border border-red-200 rounded-lg">
            <div className="flex items-center gap-2 text-red-800">
              <span className="text-red-500">❌</span>
              <div>
                <div className="font-medium">Analytics API Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
              <button
                onClick={loadDashboardData}
                className="ml-auto px-3 py-1 bg-red-100 hover:bg-red-200 text-red-700 text-sm rounded transition-colors"
              >
                Retry
              </button>
            </div>
          </div>
        )}

        {/* Loading State */}
        {isLoading && !kpiDashboard && (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <span className="ml-2 text-gray-600">Loading analytics data...</span>
          </div>
        )}

        {/* KPI Metrics Grid */}
        {kpiDashboard && (
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Key Performance Indicators</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {renderKPIMetric('Service Level', kpiDashboard.service_level)}
              {renderKPIMetric('Answer Time', kpiDashboard.answer_time)}
              {renderKPIMetric('Occupancy', kpiDashboard.occupancy)}
              {renderKPIMetric('Utilization', kpiDashboard.utilization)}
              {renderKPIMetric('Customer Satisfaction', kpiDashboard.customer_satisfaction)}
              {renderKPIMetric('First Call Resolution', kpiDashboard.first_call_resolution)}
              {renderKPIMetric('Schedule Adherence', kpiDashboard.adherence)}
              {renderKPIMetric('Shrinkage', kpiDashboard.shrinkage)}
              {renderKPIMetric('Forecast Accuracy', kpiDashboard.forecast_accuracy)}
              {renderKPIMetric('Forecast Bias', kpiDashboard.forecast_bias)}
              {renderKPIMetric('Cost per Contact', kpiDashboard.cost_per_contact)}
              {renderKPIMetric('Overtime %', kpiDashboard.overtime_percentage)}
            </div>
          </div>
        )}

        {/* Real-time Operations */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Real-time Operations</h2>
          {renderRealtimeSection()}
        </div>

        {/* System Health */}
        {realtimeMetrics && (
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">System Health</h2>
            <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="text-center">
                  <div className="text-sm text-gray-500">Integration Status</div>
                  <div className={`text-lg font-medium ${
                    realtimeMetrics.system_health.integration_status === 'healthy' ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {realtimeMetrics.system_health.integration_status}
                  </div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-500">Database Status</div>
                  <div className={`text-lg font-medium ${
                    realtimeMetrics.system_health.database_status === 'healthy' ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {realtimeMetrics.system_health.database_status}
                  </div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-500">API Response Time</div>
                  <div className={`text-lg font-medium ${
                    realtimeMetrics.system_health.api_response_time < 500 ? 'text-green-600' : 
                    realtimeMetrics.system_health.api_response_time < 1000 ? 'text-yellow-600' : 'text-red-600'
                  }`}>
                    {Math.round(realtimeMetrics.system_health.api_response_time)}ms
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Auto-refresh Info */}
        <div className="text-center text-sm text-gray-500">
          Dashboard auto-refreshes every {refreshInterval} seconds • 
          Real-time data from WFM API • 
          Last updated: {lastRefresh.toLocaleString()}
        </div>
      </div>
    </div>
  );
};

export default AnalyticsDashboard;