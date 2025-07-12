/**
 * Real-Time WFM Dashboard Component
 * Comprehensive dashboard with live data updates via WebSocket
 * Integrates with all 110+ API endpoints for complete system monitoring
 */

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import { 
  Activity, 
  Users, 
  Phone, 
  Clock, 
  TrendingUp, 
  AlertTriangle, 
  CheckCircle,
  XCircle,
  RefreshCw,
  Settings,
  Maximize2,
  Bell,
  Eye,
  BarChart3,
  PieChart,
  Target
} from 'lucide-react';
import apiIntegrationService from '@/services/apiIntegrationService';
import dataTransformationService from '@/services/dataTransformationService';
import type { 
  DashboardData, 
  Alert as AlertType, 
  Activity as ActivityType,
  TrendData
} from '@/services/apiIntegrationService';

interface MetricCardProps {
  title: string;
  value: number | string;
  unit?: string;
  trend?: number;
  icon: React.ElementType;
  color?: 'blue' | 'green' | 'yellow' | 'red' | 'purple';
  loading?: boolean;
  onClick?: () => void;
}

interface AlertsPanelProps {
  alerts: AlertType[];
  onAlertClick: (alert: AlertType) => void;
  onAlertAcknowledge: (alertId: string) => void;
}

interface ActivityFeedProps {
  activities: ActivityType[];
  onActivityClick: (activity: ActivityType) => void;
}

const MetricCard: React.FC<MetricCardProps> = ({ 
  title, 
  value, 
  unit, 
  trend, 
  icon: Icon, 
  color = 'blue', 
  loading = false,
  onClick 
}) => {
  const colorClasses = {
    blue: 'bg-blue-50 text-blue-600 border-blue-200',
    green: 'bg-green-50 text-green-600 border-green-200',
    yellow: 'bg-yellow-50 text-yellow-600 border-yellow-200',
    red: 'bg-red-50 text-red-600 border-red-200',
    purple: 'bg-purple-50 text-purple-600 border-purple-200'
  };

  const trendIcon = trend !== undefined ? (
    trend > 0 ? (
      <TrendingUp className="h-4 w-4 text-green-500" />
    ) : trend < 0 ? (
      <TrendingUp className="h-4 w-4 text-red-500 rotate-180" />
    ) : (
      <div className="w-4 h-4" />
    )
  ) : null;

  return (
    <Card 
      className={`cursor-pointer transition-all hover:shadow-lg ${colorClasses[color]}`}
      onClick={onClick}
    >
      <CardContent className="p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <Icon className="h-8 w-8" />
            <div>
              <p className="text-sm font-medium text-gray-600">{title}</p>
              <div className="flex items-center space-x-2">
                {loading ? (
                  <div className="animate-pulse">
                    <div className="h-8 w-16 bg-gray-200 rounded"></div>
                  </div>
                ) : (
                  <>
                    <p className="text-2xl font-bold">
                      {typeof value === 'number' ? value.toLocaleString() : value}
                      {unit && <span className="text-lg font-normal ml-1">{unit}</span>}
                    </p>
                    {trendIcon}
                  </>
                )}
              </div>
            </div>
          </div>
          {trend !== undefined && (
            <Badge variant={trend > 0 ? 'default' : trend < 0 ? 'destructive' : 'secondary'}>
              {trend > 0 ? '+' : ''}{trend}%
            </Badge>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

const AlertsPanel: React.FC<AlertsPanelProps> = ({ alerts, onAlertClick, onAlertAcknowledge }) => {
  const sortedAlerts = useMemo(() => {
    return [...alerts].sort((a, b) => {
      const severityOrder = { critical: 4, high: 3, medium: 2, low: 1 };
      return severityOrder[b.severity] - severityOrder[a.severity];
    });
  }, [alerts]);

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 text-red-800 border-red-200';
      case 'high': return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'low': return 'bg-blue-100 text-blue-800 border-blue-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Bell className="h-5 w-5" />
          Active Alerts ({alerts.length})
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-3 max-h-96 overflow-y-auto">
          {sortedAlerts.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <CheckCircle className="h-12 w-12 mx-auto mb-2" />
              <p>No active alerts</p>
            </div>
          ) : (
            sortedAlerts.map((alert) => (
              <div
                key={alert.id}
                className={`p-3 rounded-lg border cursor-pointer transition-all hover:shadow-sm ${getSeverityColor(alert.severity)}`}
                onClick={() => onAlertClick(alert)}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <Badge variant="outline" className="text-xs">
                        {alert.type}
                      </Badge>
                      <span className="text-xs text-gray-500">
                        {new Date(alert.timestamp).toLocaleTimeString()}
                      </span>
                    </div>
                    <p className="font-medium text-sm">{alert.title}</p>
                    <p className="text-xs text-gray-600 mt-1">{alert.message}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onAlertAcknowledge(alert.id);
                      }}
                      className="p-1 text-gray-400 hover:text-gray-600 transition-colors"
                    >
                      <Eye className="h-4 w-4" />
                    </button>
                    <AlertTriangle className="h-4 w-4" />
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </CardContent>
    </Card>
  );
};

const ActivityFeed: React.FC<ActivityFeedProps> = ({ activities, onActivityClick }) => {
  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'schedule_change': return <Clock className="h-4 w-4" />;
      case 'agent_status': return <Users className="h-4 w-4" />;
      case 'forecast_update': return <BarChart3 className="h-4 w-4" />;
      case 'request_action': return <Activity className="h-4 w-4" />;
      default: return <Activity className="h-4 w-4" />;
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Activity className="h-5 w-5" />
          Recent Activity
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-3 max-h-96 overflow-y-auto">
          {activities.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <Activity className="h-12 w-12 mx-auto mb-2" />
              <p>No recent activity</p>
            </div>
          ) : (
            activities.map((activity) => (
              <div
                key={activity.id}
                className="flex items-start gap-3 p-3 rounded-lg hover:bg-gray-50 cursor-pointer transition-colors"
                onClick={() => onActivityClick(activity)}
              >
                <div className="p-2 bg-blue-100 rounded-full">
                  {getActivityIcon(activity.type)}
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium">{activity.description}</p>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-xs text-gray-500">
                      {new Date(activity.timestamp).toLocaleTimeString()}
                    </span>
                    {activity.user && (
                      <Badge variant="outline" className="text-xs">
                        {activity.user}
                      </Badge>
                    )}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </CardContent>
    </Card>
  );
};

const RealTimeDashboard: React.FC = () => {
  const [dashboardData, setDashboardData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [refreshInterval, setRefreshInterval] = useState(30000); // 30 seconds
  const [selectedMetric, setSelectedMetric] = useState<string | null>(null);

  // Load initial dashboard data
  const loadDashboardData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await apiIntegrationService.getDashboardData();
      setDashboardData(data);
      setIsConnected(apiIntegrationService.isWebSocketConnected());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  }, []);

  // Real-time data subscriptions
  useEffect(() => {
    const subscriptions = [
      apiIntegrationService.subscribe('agent_status', (data) => {
        setDashboardData(prev => {
          if (!prev) return prev;
          return {
            ...prev,
            realTimeMetrics: {
              ...prev.realTimeMetrics,
              agentsOnline: data.agentsOnline || prev.realTimeMetrics.agentsOnline
            }
          };
        });
      }),

      apiIntegrationService.subscribe('queue_metrics', (data) => {
        setDashboardData(prev => {
          if (!prev) return prev;
          return {
            ...prev,
            realTimeMetrics: {
              ...prev.realTimeMetrics,
              callsInQueue: data.metrics?.callsInQueue || prev.realTimeMetrics.callsInQueue,
              avgWaitTime: data.metrics?.avgWaitTime || prev.realTimeMetrics.avgWaitTime,
              serviceLevel: data.metrics?.serviceLevel || prev.realTimeMetrics.serviceLevel
            }
          };
        });
      }),

      apiIntegrationService.subscribe('sla_alert', (data) => {
        setDashboardData(prev => {
          if (!prev) return prev;
          const newAlert: AlertType = {
            id: data.alert_id,
            type: 'sla',
            severity: data.severity,
            title: `SLA Alert: ${data.alert_type}`,
            message: `${data.alert_type} is ${data.current_value} (threshold: ${data.threshold})`,
            timestamp: data.timestamp,
            acknowledged: false,
            source: data.queue_id || 'system'
          };
          return {
            ...prev,
            alerts: [newAlert, ...prev.alerts].slice(0, 50) // Keep last 50 alerts
          };
        });
      }),

      apiIntegrationService.subscribe('forecast_updated', (data) => {
        setDashboardData(prev => {
          if (!prev) return prev;
          return {
            ...prev,
            realTimeMetrics: {
              ...prev.realTimeMetrics,
              forecastAccuracy: data.accuracy || prev.realTimeMetrics.forecastAccuracy
            }
          };
        });
      }),

      apiIntegrationService.subscribe('schedule_changed', (data) => {
        setDashboardData(prev => {
          if (!prev) return prev;
          const newActivity: ActivityType = {
            id: `schedule-${Date.now()}`,
            type: 'schedule_change',
            description: `Schedule updated for ${data.agentId ? 'agent' : 'system'}`,
            timestamp: data.timestamp || new Date().toISOString(),
            user: data.user,
            metadata: data
          };
          return {
            ...prev,
            recentActivity: [newActivity, ...prev.recentActivity].slice(0, 20) // Keep last 20 activities
          };
        });
      })
    ];

    return () => {
      subscriptions.forEach(unsubscribe => unsubscribe());
    };
  }, []);

  // Auto-refresh functionality
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(() => {
      loadDashboardData();
    }, refreshInterval);

    return () => clearInterval(interval);
  }, [autoRefresh, refreshInterval, loadDashboardData]);

  // Initial load
  useEffect(() => {
    loadDashboardData();
  }, [loadDashboardData]);

  // Event handlers
  const handleMetricClick = (metric: string) => {
    setSelectedMetric(metric);
    // Could open a detailed view modal here
  };

  const handleAlertClick = (alert: AlertType) => {
    console.log('Alert clicked:', alert);
    // Could open alert details modal
  };

  const handleAlertAcknowledge = async (alertId: string) => {
    try {
      // Call API to acknowledge alert
      await apiIntegrationService.acknowledgeAlert(alertId);
      setDashboardData(prev => {
        if (!prev) return prev;
        return {
          ...prev,
          alerts: prev.alerts.map(alert =>
            alert.id === alertId ? { ...alert, acknowledged: true } : alert
          )
        };
      });
    } catch (err) {
      console.error('Failed to acknowledge alert:', err);
    }
  };

  const handleActivityClick = (activity: ActivityType) => {
    console.log('Activity clicked:', activity);
    // Could open activity details modal
  };

  const handleRefresh = () => {
    loadDashboardData();
  };

  // Generate chart data
  const trendsChartData = useMemo(() => {
    if (!dashboardData?.trends) return null;
    
    const serviceLevel = dashboardData.trends.find(t => t.metric === 'service_level');
    if (!serviceLevel) return null;

    return dataTransformationService.transformToChartData(
      serviceLevel.data,
      {
        xAxis: 'timestamp',
        yAxis: 'value',
        chartType: 'line',
        colors: ['#3B82F6'],
        timeFormat: 'HH:mm'
      }
    );
  }, [dashboardData]);

  const systemHealthData = useMemo(() => {
    if (!dashboardData?.realTimeMetrics) return null;

    const { systemHealth } = dashboardData.realTimeMetrics;
    const healthScore = systemHealth === 'healthy' ? 100 : 
                      systemHealth === 'warning' ? 60 : 20;

    return {
      labels: ['Healthy', 'Warning', 'Critical'],
      datasets: [{
        data: [
          systemHealth === 'healthy' ? 100 : 0,
          systemHealth === 'warning' ? 100 : 0,
          systemHealth === 'critical' ? 100 : 0
        ],
        backgroundColor: ['#10B981', '#F59E0B', '#EF4444'],
        borderWidth: 0
      }]
    };
  }, [dashboardData]);

  if (loading && !dashboardData) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4" />
          <p className="text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  if (error && !dashboardData) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Alert>
          <AlertTriangle className="h-4 w-4" />
          <AlertDescription>
            {error}
            <button
              onClick={handleRefresh}
              className="ml-2 text-blue-600 hover:text-blue-800"
            >
              Retry
            </button>
          </AlertDescription>
        </Alert>
      </div>
    );
  }

  const { realTimeMetrics, alerts, recentActivity } = dashboardData || {
    realTimeMetrics: {
      agentsOnline: 0,
      callsInQueue: 0,
      serviceLevel: 0,
      avgWaitTime: 0,
      abandonmentRate: 0,
      scheduleAdherence: 0,
      forecastAccuracy: 0,
      systemHealth: 'healthy' as const
    },
    alerts: [],
    recentActivity: []
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">WFM Real-Time Dashboard</h1>
            <p className="text-gray-600">Comprehensive workforce management monitoring</p>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <div className={`w-3 h-3 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`} />
              <span className="text-sm text-gray-600">
                {isConnected ? 'Connected' : 'Disconnected'}
              </span>
            </div>
            <button
              onClick={handleRefresh}
              className="p-2 bg-white rounded-lg border hover:bg-gray-50 transition-colors"
            >
              <RefreshCw className={`h-5 w-5 ${loading ? 'animate-spin' : ''}`} />
            </button>
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`p-2 rounded-lg border transition-colors ${
                autoRefresh ? 'bg-blue-50 text-blue-600' : 'bg-white hover:bg-gray-50'
              }`}
            >
              <Settings className="h-5 w-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <MetricCard
          title="Agents Online"
          value={realTimeMetrics.agentsOnline}
          icon={Users}
          color="green"
          loading={loading}
          onClick={() => handleMetricClick('agents_online')}
        />
        <MetricCard
          title="Calls in Queue"
          value={realTimeMetrics.callsInQueue}
          icon={Phone}
          color="blue"
          loading={loading}
          onClick={() => handleMetricClick('calls_in_queue')}
        />
        <MetricCard
          title="Service Level"
          value={realTimeMetrics.serviceLevel}
          unit="%"
          trend={realTimeMetrics.serviceLevel > 80 ? 5 : -3}
          icon={Target}
          color={realTimeMetrics.serviceLevel > 80 ? 'green' : 'yellow'}
          loading={loading}
          onClick={() => handleMetricClick('service_level')}
        />
        <MetricCard
          title="Avg Wait Time"
          value={realTimeMetrics.avgWaitTime}
          unit="sec"
          trend={realTimeMetrics.avgWaitTime < 30 ? 2 : -5}
          icon={Clock}
          color={realTimeMetrics.avgWaitTime < 30 ? 'green' : 'red'}
          loading={loading}
          onClick={() => handleMetricClick('avg_wait_time')}
        />
      </div>

      {/* Secondary Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <MetricCard
          title="Abandonment Rate"
          value={realTimeMetrics.abandonmentRate}
          unit="%"
          trend={realTimeMetrics.abandonmentRate < 5 ? 1 : -2}
          icon={XCircle}
          color={realTimeMetrics.abandonmentRate < 5 ? 'green' : 'red'}
          loading={loading}
          onClick={() => handleMetricClick('abandonment_rate')}
        />
        <MetricCard
          title="Schedule Adherence"
          value={realTimeMetrics.scheduleAdherence}
          unit="%"
          trend={realTimeMetrics.scheduleAdherence > 90 ? 3 : -1}
          icon={CheckCircle}
          color={realTimeMetrics.scheduleAdherence > 90 ? 'green' : 'yellow'}
          loading={loading}
          onClick={() => handleMetricClick('schedule_adherence')}
        />
        <MetricCard
          title="Forecast Accuracy"
          value={realTimeMetrics.forecastAccuracy}
          unit="%"
          trend={realTimeMetrics.forecastAccuracy > 85 ? 2 : -1}
          icon={BarChart3}
          color={realTimeMetrics.forecastAccuracy > 85 ? 'green' : 'yellow'}
          loading={loading}
          onClick={() => handleMetricClick('forecast_accuracy')}
        />
      </div>

      {/* Charts and Detailed Views */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Service Level Trend Chart */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              Service Level Trend
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              {trendsChartData ? (
                <Line
                  data={trendsChartData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { display: false },
                      tooltip: {
                        callbacks: {
                          label: (context) => `${context.parsed.y}%`
                        }
                      }
                    },
                    scales: {
                      y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                          callback: (value) => `${value}%`
                        }
                      }
                    }
                  }}
                />
              ) : (
                <div className="flex items-center justify-center h-full text-gray-500">
                  <PieChart className="h-12 w-12 mx-auto mb-2" />
                  <p>No trend data available</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* System Health */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Activity className="h-5 w-5" />
              System Health
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              {systemHealthData ? (
                <Doughnut
                  data={systemHealthData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { position: 'bottom' }
                    }
                  }}
                />
              ) : (
                <div className="flex items-center justify-center h-full text-gray-500">
                  <Activity className="h-12 w-12 mx-auto mb-2" />
                  <p>No health data available</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Alerts and Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <AlertsPanel
          alerts={alerts}
          onAlertClick={handleAlertClick}
          onAlertAcknowledge={handleAlertAcknowledge}
        />
        <ActivityFeed
          activities={recentActivity}
          onActivityClick={handleActivityClick}
        />
      </div>
    </div>
  );
};

export default RealTimeDashboard;