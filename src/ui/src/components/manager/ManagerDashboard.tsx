import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { 
  Users, 
  Phone, 
  TrendingUp, 
  Clock,
  Calendar,
  BarChart3,
  FileText,
  LogOut,
  AlertTriangle,
  CheckCircle,
  XCircle,
  UserCheck
} from 'lucide-react';
import realDashboardService, { DashboardMetrics } from '../../services/realDashboardService';
import { realAuthService } from '../../services/realAuthService';

interface ManagerDashboardProps {
  managerId: number;
}

interface TeamOverview {
  total_members: number;
  active_today: number;
  on_vacation: number;
  pending_requests: number;
}

interface RecentActivity {
  type: string;
  employee: string;
  date: string;
  status: string;
}

interface KPIMetric {
  id: string;
  name: string;
  value: number;
  target?: number;
  unit: string;
  status: 'excellent' | 'good' | 'warning' | 'critical';
  trend: 'up' | 'down' | 'stable';
  changePercent: number;
  lastUpdated: Date;
}

const KPICard: React.FC<{ metric: KPIMetric }> = ({ metric }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return '#10b981';
      case 'good': return '#3b82f6';
      case 'warning': return '#f59e0b';
      case 'critical': return '#ef4444';
      default: return '#6b7280';
    }
  };

  const formatValue = (value: number, unit: string) => {
    if (unit === '%') return `${value.toFixed(1)}%`;
    if (unit === 'hours') return `${value.toFixed(1)}h`;
    return value.toFixed(1);
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return '↗️';
      case 'down': return '↘️';
      case 'stable': return '➡️';
      default: return '➡️';
    }
  };

  const getTrendColor = (trend: string) => {
    switch (trend) {
      case 'up': return 'text-green-600';
      case 'down': return 'text-red-600';
      case 'stable': return 'text-gray-600';
      default: return 'text-gray-600';
    }
  };

  const progressPercentage = metric.target ? Math.min((metric.value / metric.target) * 100, 100) : 0;

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-shadow">
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600">{metric.name}</p>
          <div className="mt-1 flex items-baseline">
            <p className="text-xl font-semibold text-gray-900">
              {formatValue(metric.value, metric.unit)}
            </p>
            {metric.target && (
              <p className="ml-2 text-sm text-gray-500">
                / {formatValue(metric.target, metric.unit)}
              </p>
            )}
          </div>
        </div>
        
        <div className="flex flex-col items-end">
          <div 
            className="w-3 h-3 rounded-full mb-2"
            style={{ backgroundColor: getStatusColor(metric.status) }}
          ></div>
          <div className={`flex items-center ${getTrendColor(metric.trend)}`}>
            <span className="text-lg mr-1">{getTrendIcon(metric.trend)}</span>
            <span className="text-sm font-medium">
              {Math.abs(metric.changePercent).toFixed(1)}%
            </span>
          </div>
        </div>
      </div>
      
      {metric.target && (
        <div className="mt-3">
          <div className="flex items-center justify-between text-xs text-gray-500 mb-1">
            <span>Progress to Target</span>
            <span>{progressPercentage.toFixed(0)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-1.5">
            <div 
              className="h-1.5 rounded-full transition-all duration-300"
              style={{ 
                width: `${progressPercentage}%`,
                backgroundColor: getStatusColor(metric.status)
              }}
            ></div>
          </div>
        </div>
      )}
    </div>
  );
};

const ManagerDashboard: React.FC<ManagerDashboardProps> = ({ managerId }) => {
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [teamMetrics, setTeamMetrics] = useState<KPIMetric[]>([]);
  const [teamOverview, setTeamOverview] = useState<TeamOverview | null>(null);
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [apiError, setApiError] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);
  
  // Load initial metrics
  useEffect(() => {
    loadMetrics();
    loadTeamData();
  }, [managerId]);
  
  const loadMetrics = async () => {
    setApiError('');
    setIsConnecting(true);
    
    try {
      // Check API health first
      const isApiHealthy = await realDashboardService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      // Make real API call for basic metrics
      const result = await realDashboardService.getDashboardMetrics();
      
      if (result.success && result.data) {
        console.log('[MANAGER DASHBOARD] Basic metrics loaded:', result.data);
        setMetrics(result.data);
      } else {
        setApiError(result.error || 'Failed to load dashboard metrics');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[MANAGER DASHBOARD] Metrics load error:', errorMessage);
    } finally {
      setIsLoading(false);
      setIsConnecting(false);
    }
  };

  const loadTeamData = async () => {
    try {
      // TODO: Replace with real API call when manager endpoints are available
      // const teamData = await managerService.getTeamDashboard(managerId);
      
      // Mock team data for now
      const mockTeamOverview: TeamOverview = {
        total_members: 12,
        active_today: 10,
        on_vacation: 2,
        pending_requests: 3
      };

      const mockTeamMetrics: KPIMetric[] = [
        {
          id: 'team-service-level',
          name: 'Team Service Level',
          value: 89.2,
          target: 85.0,
          unit: '%',
          status: 'excellent',
          trend: 'up',
          changePercent: 3.1,
          lastUpdated: new Date()
        },
        {
          id: 'team-adherence',
          name: 'Schedule Adherence',
          value: 94.7,
          target: 95.0,
          unit: '%',
          status: 'good',
          trend: 'stable',
          changePercent: 0.2,
          lastUpdated: new Date()
        },
        {
          id: 'approval-rate',
          name: 'Request Approval Rate',
          value: 91.5,
          target: 90.0,
          unit: '%',
          status: 'excellent',
          trend: 'up',
          changePercent: 2.3,
          lastUpdated: new Date()
        },
        {
          id: 'response-time',
          name: 'Avg Response Time',
          value: 1.8,
          target: 2.0,
          unit: 'hours',
          status: 'excellent',
          trend: 'down',
          changePercent: -12.5,
          lastUpdated: new Date()
        }
      ];

      const mockRecentActivity: RecentActivity[] = [
        {
          type: 'Vacation Request',
          employee: 'John Smith',
          date: '2 hours ago',
          status: 'approved'
        },
        {
          type: 'Shift Change',
          employee: 'Sarah Johnson',
          date: '4 hours ago', 
          status: 'pending'
        },
        {
          type: 'Sick Leave',
          employee: 'Mike Chen',
          date: '6 hours ago',
          status: 'approved'
        }
      ];

      setTeamOverview(mockTeamOverview);
      setTeamMetrics(mockTeamMetrics);
      setRecentActivity(mockRecentActivity);
      
    } catch (error) {
      console.error('[MANAGER DASHBOARD] Team data load error:', error);
    }
  };

  // 30-second real-time update pattern
  useEffect(() => {
    const interval = setInterval(async () => {
      setIsUpdating(true);
      
      try {
        const result = await realDashboardService.refreshMetrics();
        if (result.success && result.data) {
          setMetrics(result.data);
        }
        await loadTeamData(); // Refresh team data too
      } catch (error) {
        console.warn('[MANAGER DASHBOARD] Auto-refresh failed:', error);
      }
      
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  // Format metrics for display - REAL DATA ONLY
  const displayMetrics = metrics ? [
    {
      title: 'Active Agents',
      value: metrics.activeAgents.toString(),
      icon: Users,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100'
    },
    {
      title: 'Service Level',
      value: `${metrics.serviceLevel}%`,
      icon: TrendingUp,
      color: 'text-green-600',
      bgColor: 'bg-green-100'
    },
    {
      title: 'Calls Handled',
      value: metrics.callsHandled.toLocaleString(),
      icon: Phone,
      color: 'text-purple-600',
      bgColor: 'bg-purple-100'
    },
    {
      title: 'Average Wait Time',
      value: metrics.avgWaitTime,
      icon: Clock,
      color: 'text-orange-600',
      bgColor: 'bg-orange-100'
    }
  ] : [];
  
  const handleLogout = async () => {
    try {
      await realAuthService.logout();
    } catch (error) {
      console.error('Logout error:', error);
    }
    window.location.href = '/login';
  };

  const managerModuleLinks = [
    {
      title: 'Approval Queue',
      description: 'Review and approve employee requests',
      icon: CheckCircle,
      path: '/manager/approvals',
      color: 'bg-green-500',
      badge: teamOverview?.pending_requests || 0
    },
    {
      title: 'Team Schedule',
      description: 'View and manage team schedules',
      icon: Calendar,
      path: '/manager/schedule',
      color: 'bg-blue-500'
    },
    {
      title: 'Team Analytics',
      description: 'Performance metrics and insights',
      icon: BarChart3,
      path: '/manager/analytics',
      color: 'bg-purple-500'
    },
    {
      title: 'Reports Center',
      description: 'Generate team and performance reports',
      icon: FileText,
      path: '/reports',
      color: 'bg-indigo-500'
    }
  ];

  const getActivityStatusIcon = (status: string) => {
    switch (status) {
      case 'approved': return <CheckCircle className="h-4 w-4 text-green-600" />;
      case 'rejected': return <XCircle className="h-4 w-4 text-red-600" />;
      case 'pending': return <Clock className="h-4 w-4 text-yellow-600" />;
      default: return <AlertTriangle className="h-4 w-4 text-gray-600" />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Manager Dashboard</h1>
              <p className="text-gray-600 mt-1">Team management and performance overview</p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className={`w-2 h-2 rounded-full ${isUpdating ? 'bg-yellow-500 animate-pulse' : 'bg-green-500'}`} />
                <span className="text-sm text-gray-600">
                  Live Data - Last updated: {lastUpdate.toLocaleTimeString()}
                </span>
              </div>
              <button
                onClick={handleLogout}
                className="flex items-center space-x-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-md transition-colors"
              >
                <LogOut className="h-4 w-4" />
                <span>Logout</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Team Overview Cards */}
        {teamOverview && (
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center">
                <div className="bg-blue-100 rounded-lg p-3">
                  <Users className="h-6 w-6 text-blue-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Team Members</p>
                  <p className="text-2xl font-bold text-blue-600">{teamOverview.total_members}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center">
                <div className="bg-green-100 rounded-lg p-3">
                  <UserCheck className="h-6 w-6 text-green-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Active Today</p>
                  <p className="text-2xl font-bold text-green-600">{teamOverview.active_today}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center">
                <div className="bg-orange-100 rounded-lg p-3">
                  <Calendar className="h-6 w-6 text-orange-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">On Vacation</p>
                  <p className="text-2xl font-bold text-orange-600">{teamOverview.on_vacation}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center">
                <div className="bg-red-100 rounded-lg p-3">
                  <AlertTriangle className="h-6 w-6 text-red-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Pending Requests</p>
                  <p className="text-2xl font-bold text-red-600">{teamOverview.pending_requests}</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* System Metrics Grid */}
        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            {[1,2,3,4].map((i) => (
              <div key={i} className="bg-white rounded-lg shadow p-6 animate-pulse">
                <div className="h-20 bg-gray-200 rounded"></div>
              </div>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            {displayMetrics.map((metric) => {
              const Icon = metric.icon;
              return (
                <div key={metric.title} className="bg-white rounded-lg shadow p-6">
                  <div className="flex items-center">
                    <div className={`${metric.bgColor} rounded-lg p-3`}>
                      <Icon className={`h-6 w-6 ${metric.color}`} />
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-gray-600">{metric.title}</p>
                      <p className={`text-2xl font-bold ${metric.color}`}>{metric.value}</p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Team Performance KPIs */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Team Performance KPIs</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {teamMetrics.map((metric) => (
              <KPICard key={metric.id} metric={metric} />
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Manager Actions */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Manager Tools</h2>
            <div className="grid grid-cols-1 gap-4">
              {managerModuleLinks.map((module) => {
                const Icon = module.icon;
                return (
                  <Link
                    key={module.path}
                    to={module.path}
                    className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow p-4 block relative"
                  >
                    <div className="flex items-center">
                      <div className={`${module.color} rounded-lg p-3`}>
                        <Icon className="h-6 w-6 text-white" />
                      </div>
                      <div className="ml-4 flex-1">
                        <h3 className="text-lg font-semibold text-gray-900">
                          {module.title}
                        </h3>
                        <p className="text-gray-600 text-sm">{module.description}</p>
                      </div>
                      {module.badge !== undefined && module.badge > 0 && (
                        <div className="absolute top-2 right-2">
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                            {module.badge}
                          </span>
                        </div>
                      )}
                    </div>
                  </Link>
                );
              })}
            </div>
          </div>

          {/* Recent Activity */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Recent Team Activity</h2>
            <div className="bg-white rounded-lg shadow">
              <div className="p-6">
                <div className="space-y-4">
                  {recentActivity.map((activity, index) => (
                    <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <div className="flex items-center space-x-3">
                        {getActivityStatusIcon(activity.status)}
                        <div>
                          <p className="font-medium text-gray-900">{activity.employee}</p>
                          <p className="text-sm text-gray-600">{activity.type}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-sm text-gray-500">{activity.date}</p>
                        <p className={`text-xs font-medium ${
                          activity.status === 'approved' ? 'text-green-600' :
                          activity.status === 'rejected' ? 'text-red-600' :
                          'text-yellow-600'
                        }`}>
                          {activity.status.charAt(0).toUpperCase() + activity.status.slice(1)}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <div className="border-t border-gray-200 p-4">
                <Link 
                  to="/manager/approvals"
                  className="text-blue-600 hover:text-blue-700 font-medium text-sm"
                >
                  View all requests →
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ManagerDashboard;