/**
 * Anomaly Alerts Component
 * Real-time notifications for ML-detected anomalies
 */
import React, { useState, useEffect } from 'react';
import { AlertTriangle, Bell, BellOff, Eye, EyeOff, Clock, TrendingDown, TrendingUp, Activity } from 'lucide-react';

interface Anomaly {
  id: string;
  type: 'performance' | 'staffing' | 'demand' | 'system' | 'behavioral';
  severity: 'critical' | 'high' | 'medium' | 'low';
  title: string;
  description: string;
  detected_at: string;
  source: string;
  confidence_score: number;
  impact_score: number;
  affected_entities: string[];
  metrics: Record<string, any>;
  status: 'active' | 'investigating' | 'resolved' | 'false_positive';
  auto_resolved: boolean;
  resolution_eta?: string;
}

interface AnomalyAlertsProps {
  severity?: string[];
  type?: string[];
  showResolved?: boolean;
  autoRefresh?: boolean;
  maxItems?: number;
  className?: string;
}

export const AnomalyAlerts: React.FC<AnomalyAlertsProps> = ({
  severity = ['critical', 'high', 'medium'],
  type,
  showResolved = false,
  autoRefresh = true,
  maxItems = 10,
  className = ''
}) => {
  const [anomalies, setAnomalies] = useState<Anomaly[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [selectedAnomaly, setSelectedAnomaly] = useState<Anomaly | null>(null);
  const [filterType, setFilterType] = useState<string>('all');

  // Available anomaly types
  const anomalyTypes = [
    { id: 'all', name: 'All Types', icon: Activity },
    { id: 'performance', name: 'Performance', icon: TrendingDown },
    { id: 'staffing', name: 'Staffing', icon: TrendingUp },
    { id: 'demand', name: 'Demand', icon: Activity },
    { id: 'system', name: 'System', icon: AlertTriangle },
    { id: 'behavioral', name: 'Behavioral', icon: Eye }
  ];

  // Fetch anomalies
  const fetchAnomalies = async () => {
    try {
      const token = localStorage.getItem('auth_token');
      const params = new URLSearchParams();
      
      if (severity.length > 0) {
        severity.forEach(s => params.append('severity', s));
      }
      if (type && type.length > 0) {
        type.forEach(t => params.append('type', t));
      }
      if (filterType !== 'all') {
        params.set('type', filterType);
      }
      params.set('include_resolved', showResolved.toString());
      params.set('limit', maxItems.toString());

      const response = await fetch(`/api/v1/ai/anomalies/detect?${params}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          detection_config: {
            real_time: true,
            include_context: true
          }
        })
      });

      if (response.ok) {
        const data = await response.json();
        setAnomalies(data.anomalies || getDemoAnomalies());
        setError(null);
      } else {
        throw new Error('Failed to fetch anomalies');
      }
    } catch (err) {
      console.warn('Failed to fetch anomalies, using demo data');
      setAnomalies(getDemoAnomalies());
      setError(null);
    } finally {
      setLoading(false);
    }
  };

  // Update anomaly status
  const updateAnomalyStatus = async (anomalyId: string, newStatus: Anomaly['status']) => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`/api/v1/ai/anomalies/${anomalyId}/status`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ status: newStatus })
      });

      if (response.ok) {
        setAnomalies(prev => prev.map(anomaly => 
          anomaly.id === anomalyId ? { ...anomaly, status: newStatus } : anomaly
        ));
      }
    } catch (err) {
      console.error('Failed to update anomaly status:', err);
    }
  };

  // Demo anomalies
  const getDemoAnomalies = (): Anomaly[] => [
    {
      id: 'anom_001',
      type: 'performance',
      severity: 'critical',
      title: 'Sudden AHT Spike in Customer Service',
      description: 'Average Handle Time increased by 47% in the last 2 hours, significantly above normal variance.',
      detected_at: new Date(Date.now() - 1800000).toISOString(), // 30 min ago
      source: 'real_time_performance_monitor',
      confidence_score: 0.94,
      impact_score: 0.87,
      affected_entities: ['Customer Service Queue', 'Agent Group A', 'Phone Channel'],
      metrics: {
        current_aht: '8:47',
        normal_aht: '5:56',
        variance_threshold: '±15%',
        affected_calls: 234,
        service_level_impact: '-12%'
      },
      status: 'active',
      auto_resolved: false,
      resolution_eta: new Date(Date.now() + 3600000).toISOString()
    },
    {
      id: 'anom_002',
      type: 'staffing',
      severity: 'high',
      title: 'Unexpected Agent Shortage',
      description: 'Actual staffing is 23% below forecasted levels during peak hours, likely due to unplanned absences.',
      detected_at: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
      source: 'staffing_optimization_engine',
      confidence_score: 0.91,
      impact_score: 0.78,
      affected_entities: ['Morning Shift', 'Technical Support', 'Weekend Team'],
      metrics: {
        forecasted_agents: 45,
        actual_agents: 35,
        shortage_percentage: 23,
        unplanned_absences: 8,
        coverage_impact: 'High'
      },
      status: 'investigating',
      auto_resolved: false
    },
    {
      id: 'anom_003',
      type: 'demand',
      severity: 'medium',
      title: 'Unusual Call Volume Pattern',
      description: 'Call volume is 18% higher than predicted, with unusual concentration in technical support category.',
      detected_at: new Date(Date.now() - 5400000).toISOString(), // 1.5 hours ago
      source: 'demand_forecasting_model',
      confidence_score: 0.83,
      impact_score: 0.65,
      affected_entities: ['Technical Support', 'Inbound Calls', 'Queue Management'],
      metrics: {
        predicted_volume: 850,
        actual_volume: 1003,
        category_concentration: 'Technical Support (67%)',
        wait_time_impact: '+3.2 minutes',
        abandon_rate_change: '+2.1%'
      },
      status: 'active',
      auto_resolved: false
    },
    {
      id: 'anom_004',
      type: 'system',
      severity: 'low',
      title: 'Database Query Performance Degradation',
      description: 'Average database response time increased by 35% over the past hour, potentially affecting user experience.',
      detected_at: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
      source: 'system_monitoring_agent',
      confidence_score: 0.76,
      impact_score: 0.45,
      affected_entities: ['PostgreSQL Database', 'API Endpoints', 'User Interface'],
      metrics: {
        normal_response_time: '150ms',
        current_response_time: '203ms',
        slow_queries: 12,
        connection_pool_usage: '78%',
        cache_hit_rate: '91%'
      },
      status: 'resolved',
      auto_resolved: true
    }
  ];

  // Request notification permission
  const requestNotificationPermission = async () => {
    if ('Notification' in window) {
      const permission = await Notification.requestPermission();
      setNotificationsEnabled(permission === 'granted');
    }
  };

  // Send browser notification
  const sendNotification = (anomaly: Anomaly) => {
    if (notificationsEnabled && 'Notification' in window && Notification.permission === 'granted') {
      new Notification(`${anomaly.severity.toUpperCase()}: ${anomaly.title}`, {
        body: anomaly.description,
        icon: '/favicon.ico',
        tag: anomaly.id
      });
    }
  };

  useEffect(() => {
    fetchAnomalies();
    
    let interval: NodeJS.Timeout;
    if (autoRefresh) {
      interval = setInterval(fetchAnomalies, 30000); // Refresh every 30 seconds
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [filterType, showResolved, autoRefresh]);

  // Check for new critical anomalies and send notifications
  useEffect(() => {
    const criticalAnomalies = anomalies.filter(a => 
      a.severity === 'critical' && 
      a.status === 'active' &&
      new Date(a.detected_at).getTime() > Date.now() - 60000 // Last minute
    );

    criticalAnomalies.forEach(sendNotification);
  }, [anomalies, notificationsEnabled]);

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical':
        return <AlertTriangle className="w-4 h-4 text-red-500" />;
      case 'high':
        return <AlertTriangle className="w-4 h-4 text-orange-500" />;
      case 'medium':
        return <AlertTriangle className="w-4 h-4 text-yellow-500" />;
      case 'low':
        return <AlertTriangle className="w-4 h-4 text-blue-500" />;
      default:
        return <AlertTriangle className="w-4 h-4 text-gray-500" />;
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical':
        return 'border-red-200 bg-red-50';
      case 'high':
        return 'border-orange-200 bg-orange-50';
      case 'medium':
        return 'border-yellow-200 bg-yellow-50';
      case 'low':
        return 'border-blue-200 bg-blue-50';
      default:
        return 'border-gray-200 bg-gray-50';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-red-100 text-red-800';
      case 'investigating':
        return 'bg-yellow-100 text-yellow-800';
      case 'resolved':
        return 'bg-green-100 text-green-800';
      case 'false_positive':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatTimeAgo = (dateString: string) => {
    const now = new Date();
    const date = new Date(dateString);
    const diffMs = now.getTime() - date.getTime();
    const diffMinutes = Math.floor(diffMs / (1000 * 60));
    
    if (diffMinutes < 1) return 'Just now';
    if (diffMinutes < 60) return `${diffMinutes}m ago`;
    
    const diffHours = Math.floor(diffMinutes / 60);
    if (diffHours < 24) return `${diffHours}h ago`;
    
    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays}d ago`;
  };

  const filteredAnomalies = anomalies.filter(anomaly => {
    if (!showResolved && anomaly.status === 'resolved') return false;
    if (filterType !== 'all' && anomaly.type !== filterType) return false;
    return severity.includes(anomaly.severity);
  });

  if (loading) {
    return (
      <div className={`p-4 bg-white border border-gray-200 rounded-lg ${className}`}>
        <div className="animate-pulse space-y-3">
          <div className="h-4 bg-gray-300 rounded w-1/2"></div>
          {[1, 2, 3].map(i => (
            <div key={i} className="h-16 bg-gray-200 rounded"></div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className={`bg-white border border-gray-200 rounded-lg ${className}`}>
      {/* Header */}
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 text-red-500" />
            <h3 className="font-semibold text-gray-900">Anomaly Alerts</h3>
            <span className="px-2 py-1 bg-red-100 text-red-800 text-xs rounded-full">
              {filteredAnomalies.filter(a => a.status === 'active').length} active
            </span>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setNotificationsEnabled(!notificationsEnabled)}
              className={`p-2 rounded-lg ${notificationsEnabled ? 'text-blue-500 bg-blue-50' : 'text-gray-400 bg-gray-50'}`}
              title={notificationsEnabled ? 'Disable notifications' : 'Enable notifications'}
            >
              {notificationsEnabled ? <Bell className="w-4 h-4" /> : <BellOff className="w-4 h-4" />}
            </button>
            <button
              onClick={requestNotificationPermission}
              className="text-xs text-blue-600 hover:text-blue-800"
              title="Request notification permission"
            >
              Enable
            </button>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-1">
          {anomalyTypes.map(typeOption => {
            const Icon = typeOption.icon;
            return (
              <button
                key={typeOption.id}
                onClick={() => setFilterType(typeOption.id)}
                className={`flex items-center gap-1 px-3 py-1 rounded-full text-xs font-medium transition-colors ${
                  filterType === typeOption.id
                    ? 'bg-blue-100 text-blue-800'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                <Icon className="w-3 h-3" />
                {typeOption.name}
              </button>
            );
          })}
        </div>
      </div>

      {/* Anomalies List */}
      <div className="p-4">
        {filteredAnomalies.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <AlertTriangle className="w-12 h-12 mx-auto mb-3 text-gray-300" />
            <p>No anomalies detected</p>
            <p className="text-sm">System is operating normally</p>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredAnomalies.slice(0, maxItems).map((anomaly) => (
              <div
                key={anomaly.id}
                className={`p-4 border rounded-lg cursor-pointer transition-all ${getSeverityColor(anomaly.severity)} ${
                  selectedAnomaly?.id === anomaly.id ? 'ring-2 ring-blue-500' : ''
                }`}
                onClick={() => setSelectedAnomaly(selectedAnomaly?.id === anomaly.id ? null : anomaly)}
              >
                <div className="flex items-start justify-between mb-2">
                  <div className="flex items-start gap-3">
                    {getSeverityIcon(anomaly.severity)}
                    <div className="flex-1">
                      <h4 className="font-medium text-gray-900 mb-1">
                        {anomaly.title}
                      </h4>
                      <div className="flex items-center gap-3 text-sm text-gray-600">
                        <span className="capitalize">{anomaly.type}</span>
                        <span>•</span>
                        <span>{formatTimeAgo(anomaly.detected_at)}</span>
                        <span>•</span>
                        <span>Confidence: {(anomaly.confidence_score * 100).toFixed(0)}%</span>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(anomaly.status)}`}>
                      {anomaly.status.replace('_', ' ')}
                    </span>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setSelectedAnomaly(selectedAnomaly?.id === anomaly.id ? null : anomaly);
                      }}
                    >
                      {selectedAnomaly?.id === anomaly.id ? 
                        <EyeOff className="w-4 h-4 text-gray-400" /> : 
                        <Eye className="w-4 h-4 text-gray-400" />
                      }
                    </button>
                  </div>
                </div>

                <p className="text-sm text-gray-700 mb-3">
                  {anomaly.description}
                </p>

                {/* Impact and Confidence Bars */}
                <div className="grid grid-cols-2 gap-4 mb-3">
                  <div>
                    <div className="text-xs text-gray-600 mb-1">Impact Score</div>
                    <div className="flex items-center gap-2">
                      <div className="flex-1 bg-gray-200 rounded-full h-2">
                        <div 
                          className="bg-red-500 h-2 rounded-full" 
                          style={{ width: `${anomaly.impact_score * 100}%` }}
                        ></div>
                      </div>
                      <span className="text-xs font-medium">{(anomaly.impact_score * 100).toFixed(0)}%</span>
                    </div>
                  </div>
                  <div>
                    <div className="text-xs text-gray-600 mb-1">Confidence</div>
                    <div className="flex items-center gap-2">
                      <div className="flex-1 bg-gray-200 rounded-full h-2">
                        <div 
                          className="bg-blue-500 h-2 rounded-full" 
                          style={{ width: `${anomaly.confidence_score * 100}%` }}
                        ></div>
                      </div>
                      <span className="text-xs font-medium">{(anomaly.confidence_score * 100).toFixed(0)}%</span>
                    </div>
                  </div>
                </div>

                {/* Affected Entities */}
                <div className="flex flex-wrap gap-1 mb-3">
                  {anomaly.affected_entities.slice(0, 3).map((entity, index) => (
                    <span key={index} className="px-2 py-1 bg-white bg-opacity-60 text-gray-700 text-xs rounded">
                      {entity}
                    </span>
                  ))}
                  {anomaly.affected_entities.length > 3 && (
                    <span className="px-2 py-1 bg-white bg-opacity-60 text-gray-500 text-xs rounded">
                      +{anomaly.affected_entities.length - 3} more
                    </span>
                  )}
                </div>

                {/* Expanded Details */}
                {selectedAnomaly?.id === anomaly.id && (
                  <div className="mt-4 pt-4 border-t border-gray-300">
                    <div className="grid grid-cols-2 gap-4 mb-4">
                      <div>
                        <h5 className="text-sm font-medium text-gray-900 mb-2">Detection Details</h5>
                        <div className="space-y-1 text-xs">
                          <div className="flex justify-between">
                            <span className="text-gray-600">Source:</span>
                            <span className="text-gray-900">{anomaly.source}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Auto-resolved:</span>
                            <span className="text-gray-900">{anomaly.auto_resolved ? 'Yes' : 'No'}</span>
                          </div>
                          {anomaly.resolution_eta && (
                            <div className="flex justify-between">
                              <span className="text-gray-600">ETA:</span>
                              <span className="text-gray-900">
                                {new Date(anomaly.resolution_eta).toLocaleString()}
                              </span>
                            </div>
                          )}
                        </div>
                      </div>
                      <div>
                        <h5 className="text-sm font-medium text-gray-900 mb-2">Metrics</h5>
                        <div className="space-y-1 text-xs">
                          {Object.entries(anomaly.metrics).slice(0, 4).map(([key, value]) => (
                            <div key={key} className="flex justify-between">
                              <span className="text-gray-600 capitalize">{key.replace('_', ' ')}:</span>
                              <span className="text-gray-900 font-medium">{String(value)}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>

                    {/* Action Buttons */}
                    {anomaly.status === 'active' && (
                      <div className="flex gap-2">
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            updateAnomalyStatus(anomaly.id, 'investigating');
                          }}
                          className="px-3 py-1 bg-yellow-500 text-white rounded text-sm hover:bg-yellow-600"
                        >
                          Mark as Investigating
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            updateAnomalyStatus(anomaly.id, 'resolved');
                          }}
                          className="px-3 py-1 bg-green-500 text-white rounded text-sm hover:bg-green-600"
                        >
                          Mark as Resolved
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            updateAnomalyStatus(anomaly.id, 'false_positive');
                          }}
                          className="px-3 py-1 bg-gray-500 text-white rounded text-sm hover:bg-gray-600"
                        >
                          False Positive
                        </button>
                      </div>
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default AnomalyAlerts;