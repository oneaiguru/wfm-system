import React, { useState, useEffect } from 'react';
import { 
  AlertTriangle,
  Bell, 
  Settings, 
  TrendingUp,
  CheckCircle, 
  RefreshCw,
  Eye,
  MoreHorizontal,
  Filter,
  Plus,
  Clock,
  User,
  MessageSquare,
  ExternalLink
} from 'lucide-react';
import realAlertsService, { Alert, AlertsData, AlertFilters } from '../../services/realAlertsService';

// Performance Component 4: Alert Configuration using GET /api/v1/alerts/list
// This component manages alert rules and configurations with real-time monitoring

const AlertConfiguration: React.FC = () => {
  const [alertsData, setAlertsData] = useState<AlertsData | null>(null);
  const [selectedAlert, setSelectedAlert] = useState<Alert | null>(null);
  const [filters, setFilters] = useState<AlertFilters>({ status: 'all' });
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [apiError, setApiError] = useState<string>('');
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [showFilters, setShowFilters] = useState(false);

  // Load initial alerts data
  useEffect(() => {
    loadAlertsData();
  }, [filters]);

  const loadAlertsData = async () => {
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realAlertsService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      // Make real API call to GET /api/v1/alerts/list
      const result = await realAlertsService.getActiveAlerts(filters);
      
      if (result.success && result.data) {
        console.log('[ALERT CONFIG] Alerts data loaded:', result.data);
        setAlertsData(result.data);
        setLastUpdate(new Date());
      } else {
        setApiError(result.error || 'Failed to load alerts configuration');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[ALERT CONFIG] Alerts load error:', errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  // Auto-refresh every 30 seconds
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(async () => {
      setIsUpdating(true);
      
      try {
        const result = await realAlertsService.refreshAlerts();
        if (result.success && result.data) {
          setAlertsData(result.data);
        }
      } catch (error) {
        console.warn('[ALERT CONFIG] Auto-refresh failed:', error);
      }
      
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 30000);

    return () => clearInterval(interval);
  }, [autoRefresh]);

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'text-red-600 bg-red-100 border-red-200';
      case 'high': return 'text-orange-600 bg-orange-100 border-orange-200';
      case 'medium': return 'text-yellow-600 bg-yellow-100 border-yellow-200';
      case 'low': return 'text-blue-600 bg-blue-100 border-blue-200';
      default: return 'text-gray-600 bg-gray-100 border-gray-200';
    }
  };

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical': return <AlertTriangle className="h-4 w-4 text-red-500" />;
      case 'high': return <AlertTriangle className="h-4 w-4 text-orange-500" />;
      case 'medium': return <Bell className="h-4 w-4 text-yellow-500" />;
      case 'low': return <Bell className="h-4 w-4 text-blue-500" />;
      default: return <Bell className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusIcon = (alert: Alert) => {
    if (alert.resolved) return <CheckCircle className="h-4 w-4 text-green-500" />;
    if (alert.acknowledged) return <Eye className="h-4 w-4 text-blue-500" />;
    return <Clock className="h-4 w-4 text-orange-500" />;
  };

  const handleAcknowledgeAlert = async (alertId: string) => {
    try {
      const result = await realAlertsService.acknowledgeAlert(alertId, 'Acknowledged from Alert Configuration');
      if (result.success) {
        await loadAlertsData(); // Refresh data
      } else {
        setApiError(result.error || 'Failed to acknowledge alert');
      }
    } catch (error) {
      console.error('[ALERT CONFIG] Acknowledge failed:', error);
    }
  };

  const handleResolveAlert = async (alertId: string) => {
    try {
      const result = await realAlertsService.resolveAlert(alertId, 'Resolved from Alert Configuration');
      if (result.success) {
        await loadAlertsData(); // Refresh data
      } else {
        setApiError(result.error || 'Failed to resolve alert');
      }
    } catch (error) {
      console.error('[ALERT CONFIG] Resolve failed:', error);
    }
  };

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleString();
  };

  const getAlertAge = (timestamp: string) => {
    const now = new Date();
    const alertTime = new Date(timestamp);
    const diffMs = now.getTime() - alertTime.getTime();
    const diffMins = Math.floor(diffMs / (1000 * 60));
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffDays > 0) return `${diffDays}d ago`;
    if (diffHours > 0) return `${diffHours}h ago`;
    if (diffMins > 0) return `${diffMins}m ago`;
    return 'Just now';
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
        <div className="grid grid-cols-1 gap-4">
          {[1,2,3,4,5].map((i) => (
            <div key={i} className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 animate-pulse">
              <div className="h-16 bg-gray-200 rounded"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  const alerts = alertsData?.alerts || [];

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
              onClick={loadAlertsData}
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
              <Settings className="h-6 w-6 mr-2 text-blue-600" />
              Alert Configuration & Management
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">🔔</span>
              Monitor and manage system alerts and notifications
            </p>
          </div>
          
          <div className="text-right">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => setShowFilters(!showFilters)}
                className="flex items-center space-x-2 px-3 py-1 bg-gray-100 text-gray-700 rounded text-sm hover:bg-gray-200"
              >
                <Filter className="h-4 w-4" />
                <span>Filters</span>
              </button>
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

        {/* Filters Panel */}
        {showFilters && (
          <div className="mt-6 p-4 bg-gray-50 rounded-lg">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select
                  value={filters.status || 'all'}
                  onChange={(e) => setFilters({...filters, status: e.target.value as any})}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                >
                  <option value="all">All Alerts</option>
                  <option value="active">Active Only</option>
                  <option value="acknowledged">Acknowledged</option>
                  <option value="resolved">Resolved</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Severity</label>
                <select
                  onChange={(e) => {
                    const severity = e.target.value;
                    setFilters({...filters, severity: severity ? [severity] : undefined});
                  }}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                >
                  <option value="">All Severities</option>
                  <option value="critical">Critical</option>
                  <option value="high">High</option>
                  <option value="medium">Medium</option>
                  <option value="low">Low</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                <select
                  onChange={(e) => {
                    const type = e.target.value;
                    setFilters({...filters, type: type ? [type] : undefined});
                  }}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                >
                  <option value="">All Types</option>
                  <option value="sla_breach">SLA Breach</option>
                  <option value="queue_overflow">Queue Overflow</option>
                  <option value="agent_status">Agent Status</option>
                  <option value="system_error">System Error</option>
                  <option value="performance_degradation">Performance</option>
                </select>
              </div>
              <div className="flex items-end">
                <button
                  onClick={() => setFilters({ status: 'all' })}
                  className="w-full px-3 py-2 bg-gray-200 text-gray-700 rounded-md text-sm hover:bg-gray-300"
                >
                  Clear Filters
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Alert Statistics */}
      {alertsData && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center">
              <Bell className="h-6 w-6 text-blue-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-600">Total Alerts</p>
                <p className="text-2xl font-bold text-blue-600">{alertsData.totalCount}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center">
              <AlertTriangle className="h-6 w-6 text-orange-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-600">Active Alerts</p>
                <p className="text-2xl font-bold text-orange-600">{alertsData.activeCount}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center">
              <AlertTriangle className="h-6 w-6 text-red-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-600">Critical Alerts</p>
                <p className="text-2xl font-bold text-red-600">{alertsData.criticalCount}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="flex items-center">
              <TrendingUp className="h-6 w-6 text-green-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-600">Resolution Rate</p>
                <p className="text-2xl font-bold text-green-600">
                  {alertsData.totalCount > 0 ? 
                    (((alertsData.totalCount - alertsData.activeCount) / alertsData.totalCount) * 100).toFixed(1) : 0
                  }%
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Alerts List */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900 flex items-center">
            <Bell className="h-5 w-5 mr-2" />
            Alert Management ({alerts.length})
          </h3>
          <button className="flex items-center space-x-2 px-3 py-1 bg-blue-100 text-blue-700 rounded text-sm hover:bg-blue-200">
            <Plus className="h-4 w-4" />
            <span>Create Alert Rule</span>
          </button>
        </div>

        <div className="overflow-x-auto">
          {alerts.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              <Bell className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <div className="text-lg font-medium">No alerts found</div>
              <div className="text-sm">All systems are running normally</div>
            </div>
          ) : (
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Alert</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Severity</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Source</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Age</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {alerts.map((alert) => (
                  <tr key={alert.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-start space-x-3">
                        {getSeverityIcon(alert.severity)}
                        <div className="min-w-0 flex-1">
                          <div className="font-medium text-gray-900">{alert.title}</div>
                          <div className="text-sm text-gray-500 truncate max-w-xs">{alert.message}</div>
                          {alert.metadata?.affectedUsers && (
                            <div className="text-xs text-gray-400 mt-1">
                              Affects {alert.metadata.affectedUsers} users
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium uppercase ${getSeverityColor(alert.severity)}`}>
                        {alert.severity}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center space-x-2">
                        {getStatusIcon(alert)}
                        <span className="text-sm text-gray-900">
                          {alert.resolved ? 'Resolved' : alert.acknowledged ? 'Acknowledged' : 'Active'}
                        </span>
                      </div>
                      {alert.acknowledgedBy && (
                        <div className="text-xs text-gray-500 mt-1">
                          by {alert.acknowledgedBy}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {alert.source}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {getAlertAge(alert.timestamp)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <div className="flex items-center space-x-2">
                        {!alert.acknowledged && !alert.resolved && (
                          <button
                            onClick={() => handleAcknowledgeAlert(alert.id)}
                            className="text-blue-600 hover:text-blue-800"
                            title="Acknowledge"
                          >
                            <Eye className="h-4 w-4" />
                          </button>
                        )}
                        {alert.acknowledged && !alert.resolved && (
                          <button
                            onClick={() => handleResolveAlert(alert.id)}
                            className="text-green-600 hover:text-green-800"
                            title="Resolve"
                          >
                            <CheckCircle className="h-4 w-4" />
                          </button>
                        )}
                        <button
                          onClick={() => setSelectedAlert(alert)}
                          className="text-gray-600 hover:text-gray-800"
                          title="View Details"
                        >
                          <ExternalLink className="h-4 w-4" />
                        </button>
                        <button className="text-gray-600 hover:text-gray-800">
                          <MoreHorizontal className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Alert Details Modal */}
      {selectedAlert && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg max-w-2xl w-full mx-4 max-h-96 overflow-y-auto">
            <div className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Alert Details</h3>
                <button
                  onClick={() => setSelectedAlert(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              
              <div className="space-y-4">
                <div>
                  <div className="flex items-center space-x-2 mb-2">
                    {getSeverityIcon(selectedAlert.severity)}
                    <span className={`px-2 py-1 rounded text-xs font-medium ${getSeverityColor(selectedAlert.severity)}`}>
                      {selectedAlert.severity.toUpperCase()}
                    </span>
                  </div>
                  <h4 className="font-medium text-gray-900">{selectedAlert.title}</h4>
                  <p className="text-sm text-gray-600 mt-1">{selectedAlert.message}</p>
                  {selectedAlert.description && (
                    <p className="text-sm text-gray-500 mt-2">{selectedAlert.description}</p>
                  )}
                </div>
                
                <div className="border-t pt-4">
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span className="font-medium text-gray-700">Type:</span>
                      <span className="ml-2 text-gray-600">{selectedAlert.type}</span>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Source:</span>
                      <span className="ml-2 text-gray-600">{selectedAlert.source}</span>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Created:</span>
                      <span className="ml-2 text-gray-600">{formatTimestamp(selectedAlert.timestamp)}</span>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Status:</span>
                      <span className="ml-2 text-gray-600">
                        {selectedAlert.resolved ? 'Resolved' : selectedAlert.acknowledged ? 'Acknowledged' : 'Active'}
                      </span>
                    </div>
                  </div>
                </div>
                
                {selectedAlert.metadata && (
                  <div className="border-t pt-4">
                    <h5 className="font-medium text-gray-700 mb-2">Additional Information</h5>
                    <div className="bg-gray-50 p-3 rounded text-sm">
                      <pre className="whitespace-pre-wrap">{JSON.stringify(selectedAlert.metadata, null, 2)}</pre>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Status Bar */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
              <span className="text-sm text-gray-600">Alert monitoring active</span>
            </div>
            <div className="text-sm text-gray-500">
              Refresh rate: 30 seconds
            </div>
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            <span>🔔 {alertsData?.totalCount || 0} Total</span>
            <span>🚨 {alertsData?.activeCount || 0} Active</span>
            <span>⚠️ {alertsData?.criticalCount || 0} Critical</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AlertConfiguration;