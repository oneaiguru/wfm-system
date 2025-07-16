import React, { useState, useEffect } from 'react';
import { 
  AlertTriangle, 
  CheckCircle, 
  XCircle, 
  Clock,
  User,
  Filter,
  Bell,
  BellOff,
  MessageSquare,
  Eye,
  EyeOff,
  ArrowUp,
  RefreshCw,
  MoreHorizontal,
  Plus,
  Search
} from 'lucide-react';
import realAlertsService, { Alert, AlertsData, AlertFilters } from '../../services/realAlertsService';

// BDD: Comprehensive alerts management panel with real-time notifications
// Based on: alerts-management-dashboard.feature

const AlertsPanel: React.FC = () => {
  const [alertsData, setAlertsData] = useState<AlertsData | null>(null);
  const [selectedAlerts, setSelectedAlerts] = useState<Set<string>>(new Set());
  const [filters, setFilters] = useState<AlertFilters>({ status: 'active' });
  const [showFilters, setShowFilters] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [apiError, setApiError] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [selectedAlert, setSelectedAlert] = useState<Alert | null>(null);
  const [showCommentDialog, setShowCommentDialog] = useState(false);
  const [commentText, setCommentText] = useState('');

  // Load initial alerts data
  useEffect(() => {
    loadAlertsData();
  }, [filters]);

  const loadAlertsData = async () => {
    setApiError('');
    setIsConnecting(true);
    
    try {
      // Check API health first
      const isApiHealthy = await realAlertsService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      // Make real API call
      const result = await realAlertsService.getActiveAlerts(filters);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Alerts data loaded:', result.data);
        setAlertsData(result.data);
        setLastUpdate(new Date());
      } else {
        setApiError(result.error || 'Failed to load alerts');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Alerts load error:', errorMessage);
    } finally {
      setIsLoading(false);
      setIsConnecting(false);
    }
  };

  // Real-time updates every 30 seconds
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
        console.warn('[REAL COMPONENT] Auto-refresh failed:', error);
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
      case 'critical': return '🔴';
      case 'high': return '🟠';
      case 'medium': return '🟡';
      case 'low': return '🔵';
      default: return '⚪';
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'sla_breach': return '⏰';
      case 'queue_overflow': return '📞';
      case 'agent_status': return '👤';
      case 'system_error': return '⚠️';
      case 'performance_degradation': return '📉';
      case 'threshold_exceeded': return '📊';
      default: return '🔔';
    }
  };

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));
    
    if (diffMinutes < 1) return 'Just now';
    if (diffMinutes < 60) return `${diffMinutes}m ago`;
    if (diffMinutes < 1440) return `${Math.floor(diffMinutes / 60)}h ago`;
    return date.toLocaleDateString();
  };

  const handleAlertSelection = (alertId: string) => {
    const newSelected = new Set(selectedAlerts);
    if (newSelected.has(alertId)) {
      newSelected.delete(alertId);
    } else {
      newSelected.add(alertId);
    }
    setSelectedAlerts(newSelected);
  };

  const handleSelectAll = () => {
    if (selectedAlerts.size === filteredAlerts.length) {
      setSelectedAlerts(new Set());
    } else {
      setSelectedAlerts(new Set(filteredAlerts.map(alert => alert.id)));
    }
  };

  const handleAcknowledgeAlert = async (alertId: string, comment?: string) => {
    try {
      const result = await realAlertsService.acknowledgeAlert(alertId, comment);
      if (result.success) {
        await loadAlertsData(); // Refresh data
        setSelectedAlerts(new Set()); // Clear selections
      } else {
        console.error('Acknowledge failed:', result.error);
      }
    } catch (error) {
      console.error('Acknowledge error:', error);
    }
  };

  const handleBulkAcknowledge = async () => {
    if (selectedAlerts.size === 0) return;
    
    try {
      const result = await realAlertsService.bulkAcknowledgeAlerts(
        Array.from(selectedAlerts), 
        commentText || undefined
      );
      if (result.success) {
        await loadAlertsData();
        setSelectedAlerts(new Set());
        setShowCommentDialog(false);
        setCommentText('');
      }
    } catch (error) {
      console.error('Bulk acknowledge error:', error);
    }
  };

  const handleResolveAlert = async (alertId: string, resolution: string) => {
    try {
      const result = await realAlertsService.resolveAlert(alertId, resolution);
      if (result.success) {
        await loadAlertsData();
      }
    } catch (error) {
      console.error('Resolve error:', error);
    }
  };

  const handleEscalateAlert = async (alertId: string, escalateTo: string, reason: string) => {
    try {
      const result = await realAlertsService.escalateAlert(alertId, escalateTo, reason);
      if (result.success) {
        await loadAlertsData();
      }
    } catch (error) {
      console.error('Escalate error:', error);
    }
  };

  // Filter and search alerts
  const alerts = alertsData?.alerts || [];
  const filteredAlerts = alerts.filter(alert => {
    if (searchTerm) {
      const searchLower = searchTerm.toLowerCase();
      return alert.title.toLowerCase().includes(searchLower) ||
             alert.message.toLowerCase().includes(searchLower) ||
             alert.source.toLowerCase().includes(searchLower);
    }
    return true;
  });

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
        <div className="space-y-4">
          {[1,2,3,4,5].map((i) => (
            <div key={i} className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 animate-pulse">
              <div className="h-16 bg-gray-200 rounded"></div>
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
              onClick={loadAlertsData}
              className="ml-auto px-3 py-1 bg-red-100 text-red-700 rounded text-sm hover:bg-red-200"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* Header with Controls */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <Bell className="h-6 w-6 mr-2 text-red-600" />
              Alerts Management
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">🚨</span>
              Real-time monitoring and incident management
            </p>
          </div>
          
          <div className="flex items-center space-x-4">
            {/* Search */}
            <div className="relative">
              <Search className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search alerts..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Filter Toggle */}
            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`flex items-center space-x-2 px-3 py-2 rounded-md text-sm transition-colors ${
                showFilters ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'
              }`}
            >
              <Filter className="h-4 w-4" />
              <span>Filters</span>
            </button>

            {/* Auto-refresh Toggle */}
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`flex items-center space-x-2 px-3 py-2 rounded-md text-sm transition-colors ${
                autoRefresh ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
              }`}
            >
              {autoRefresh ? <Bell className="h-4 w-4" /> : <BellOff className="h-4 w-4" />}
              <span>{autoRefresh ? 'Live' : 'Paused'}</span>
            </button>

            {/* Refresh Button */}
            <button
              onClick={loadAlertsData}
              className="flex items-center space-x-2 px-3 py-2 bg-blue-600 text-white rounded-md text-sm hover:bg-blue-700"
            >
              <RefreshCw className={`h-4 w-4 ${isUpdating ? 'animate-spin' : ''}`} />
              <span>Refresh</span>
            </button>
          </div>
        </div>

        {/* Summary Stats */}
        <div className="mt-6 grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-gray-50 rounded-lg p-4">
            <div className="flex items-center">
              <Bell className="h-5 w-5 text-gray-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-600">Total Alerts</p>
                <p className="text-xl font-bold text-gray-900">{alertsData?.totalCount || 0}</p>
              </div>
            </div>
          </div>
          <div className="bg-yellow-50 rounded-lg p-4">
            <div className="flex items-center">
              <AlertTriangle className="h-5 w-5 text-yellow-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-yellow-600">Active</p>
                <p className="text-xl font-bold text-yellow-900">{alertsData?.activeCount || 0}</p>
              </div>
            </div>
          </div>
          <div className="bg-red-50 rounded-lg p-4">
            <div className="flex items-center">
              <XCircle className="h-5 w-5 text-red-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-red-600">Critical</p>
                <p className="text-xl font-bold text-red-900">{alertsData?.criticalCount || 0}</p>
              </div>
            </div>
          </div>
          <div className="bg-blue-50 rounded-lg p-4">
            <div className="flex items-center">
              <Clock className="h-5 w-5 text-blue-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-blue-600">Last Update</p>
                <p className="text-sm font-semibold text-blue-900">{lastUpdate.toLocaleTimeString()}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Filters Panel */}
      {showFilters && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Filter Alerts</h3>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {/* Status Filter */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
              <select
                value={filters.status || 'all'}
                onChange={(e) => setFilters({...filters, status: e.target.value as any})}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All</option>
                <option value="active">Active</option>
                <option value="acknowledged">Acknowledged</option>
                <option value="resolved">Resolved</option>
              </select>
            </div>

            {/* Severity Filter */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Severity</label>
              <select
                multiple
                value={filters.severity || []}
                onChange={(e) => setFilters({...filters, severity: Array.from(e.target.selectedOptions, option => option.value)})}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="critical">Critical</option>
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
              </select>
            </div>

            {/* Type Filter */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Type</label>
              <select
                multiple
                value={filters.type || []}
                onChange={(e) => setFilters({...filters, type: Array.from(e.target.selectedOptions, option => option.value)})}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="sla_breach">SLA Breach</option>
                <option value="queue_overflow">Queue Overflow</option>
                <option value="agent_status">Agent Status</option>
                <option value="system_error">System Error</option>
                <option value="performance_degradation">Performance</option>
                <option value="threshold_exceeded">Threshold</option>
              </select>
            </div>

            {/* Clear Filters */}
            <div className="flex items-end">
              <button
                onClick={() => setFilters({ status: 'active' })}
                className="w-full px-3 py-2 bg-gray-100 text-gray-700 rounded-md text-sm hover:bg-gray-200"
              >
                Clear Filters
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Bulk Actions */}
      {selectedAlerts.size > 0 && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <CheckCircle className="h-5 w-5 text-blue-600" />
              <span className="text-sm font-medium text-blue-900">
                {selectedAlerts.size} alert{selectedAlerts.size > 1 ? 's' : ''} selected
              </span>
            </div>
            <div className="flex items-center space-x-2">
              <button
                onClick={() => setShowCommentDialog(true)}
                className="px-3 py-1 bg-blue-600 text-white rounded text-sm hover:bg-blue-700"
              >
                Acknowledge Selected
              </button>
              <button
                onClick={() => setSelectedAlerts(new Set())}
                className="px-3 py-1 bg-gray-100 text-gray-700 rounded text-sm hover:bg-gray-200"
              >
                Clear Selection
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Alerts List */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900">
              Alerts ({filteredAlerts.length})
            </h3>
            <div className="flex items-center space-x-2">
              <button
                onClick={handleSelectAll}
                className="text-sm text-blue-600 hover:text-blue-800"
              >
                {selectedAlerts.size === filteredAlerts.length ? 'Deselect All' : 'Select All'}
              </button>
            </div>
          </div>
        </div>

        <div className="divide-y divide-gray-200">
          {filteredAlerts.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <Bell className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <p className="text-lg font-medium">No alerts found</p>
              <p className="text-sm">All systems are operating normally</p>
            </div>
          ) : (
            filteredAlerts.map((alert) => (
              <div
                key={alert.id}
                className={`p-6 hover:bg-gray-50 transition-colors ${selectedAlerts.has(alert.id) ? 'bg-blue-50' : ''}`}
              >
                <div className="flex items-start space-x-4">
                  {/* Selection Checkbox */}
                  <input
                    type="checkbox"
                    checked={selectedAlerts.has(alert.id)}
                    onChange={() => handleAlertSelection(alert.id)}
                    className="mt-1 h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                  />

                  {/* Alert Content */}
                  <div className="flex-1">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center space-x-2 mb-2">
                          <span className="text-xl">{getSeverityIcon(alert.severity)}</span>
                          <span className="text-xl">{getTypeIcon(alert.type)}</span>
                          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getSeverityColor(alert.severity)}`}>
                            {alert.severity.toUpperCase()}
                          </span>
                          <span className="text-xs text-gray-500">{alert.type.replace('_', ' ').toUpperCase()}</span>
                          {alert.acknowledged && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                              <Eye className="h-3 w-3 mr-1" />
                              Acknowledged
                            </span>
                          )}
                          {alert.resolved && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                              <CheckCircle className="h-3 w-3 mr-1" />
                              Resolved
                            </span>
                          )}
                        </div>

                        <h4 className="text-lg font-semibold text-gray-900 mb-1">{alert.title}</h4>
                        <p className="text-gray-700 mb-2">{alert.message}</p>
                        
                        {alert.description && (
                          <p className="text-sm text-gray-600 mb-2">{alert.description}</p>
                        )}

                        {alert.metadata && (
                          <div className="text-sm text-gray-500 space-y-1">
                            {alert.metadata.queueId && <div>Queue: {alert.metadata.queueId}</div>}
                            {alert.metadata.agentId && <div>Agent: {alert.metadata.agentId}</div>}
                            {alert.metadata.currentValue && alert.metadata.threshold && (
                              <div>Value: {alert.metadata.currentValue} (Threshold: {alert.metadata.threshold})</div>
                            )}
                            {alert.metadata.affectedUsers && (
                              <div>Affected Users: {alert.metadata.affectedUsers}</div>
                            )}
                          </div>
                        )}

                        <div className="flex items-center space-x-4 mt-3 text-sm text-gray-500">
                          <span className="flex items-center">
                            <Clock className="h-4 w-4 mr-1" />
                            {formatTimestamp(alert.timestamp)}
                          </span>
                          <span className="flex items-center">
                            <User className="h-4 w-4 mr-1" />
                            {alert.source}
                          </span>
                          {alert.acknowledgedBy && (
                            <span>Acknowledged by {alert.acknowledgedBy}</span>
                          )}
                        </div>
                      </div>

                      {/* Actions */}
                      <div className="flex items-center space-x-2">
                        {!alert.acknowledged && (
                          <button
                            onClick={() => handleAcknowledgeAlert(alert.id)}
                            className="p-2 text-blue-600 hover:bg-blue-100 rounded transition-colors"
                            title="Acknowledge"
                          >
                            <Eye className="h-4 w-4" />
                          </button>
                        )}
                        
                        {!alert.resolved && (
                          <button
                            onClick={() => handleResolveAlert(alert.id, 'Manual resolution')}
                            className="p-2 text-green-600 hover:bg-green-100 rounded transition-colors"
                            title="Resolve"
                          >
                            <CheckCircle className="h-4 w-4" />
                          </button>
                        )}

                        <button
                          onClick={() => handleEscalateAlert(alert.id, 'supervisor', 'Manual escalation')}
                          className="p-2 text-orange-600 hover:bg-orange-100 rounded transition-colors"
                          title="Escalate"
                        >
                          <ArrowUp className="h-4 w-4" />
                        </button>

                        <button
                          onClick={() => setSelectedAlert(alert)}
                          className="p-2 text-gray-600 hover:bg-gray-100 rounded transition-colors"
                          title="More Actions"
                        >
                          <MoreHorizontal className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Comment Dialog for Bulk Actions */}
      {showCommentDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Acknowledge {selectedAlerts.size} Alert{selectedAlerts.size > 1 ? 's' : ''}
            </h3>
            <textarea
              value={commentText}
              onChange={(e) => setCommentText(e.target.value)}
              placeholder="Add a comment (optional)..."
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              rows={3}
            />
            <div className="flex items-center justify-end space-x-3 mt-4">
              <button
                onClick={() => {
                  setShowCommentDialog(false);
                  setCommentText('');
                }}
                className="px-4 py-2 text-gray-700 bg-gray-100 rounded hover:bg-gray-200"
              >
                Cancel
              </button>
              <button
                onClick={handleBulkAcknowledge}
                className="px-4 py-2 text-white bg-blue-600 rounded hover:bg-blue-700"
              >
                Acknowledge
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Real-time Status Bar */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className={`w-2 h-2 rounded-full animate-pulse mr-2 ${autoRefresh ? 'bg-green-500' : 'bg-gray-400'}`}></div>
              <span className="text-sm text-gray-600">
                {autoRefresh ? 'Real-time monitoring active' : 'Monitoring paused'}
              </span>
            </div>
            <div className="text-sm text-gray-500">
              Auto-refresh: {autoRefresh ? '30 seconds' : 'Disabled'}
            </div>
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            <span>🔴 {alerts.filter(a => a.severity === 'critical').length} Critical</span>
            <span>🟠 {alerts.filter(a => a.severity === 'high').length} High</span>
            <span>🟡 {alerts.filter(a => a.severity === 'medium').length} Medium</span>
            <span>🔵 {alerts.filter(a => a.severity === 'low').length} Low</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AlertsPanel;