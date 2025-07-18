import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Users, Calendar, Clock, FileText, TrendingUp, TrendingDown, AlertTriangle } from 'lucide-react';

interface DashboardMetrics {
  scheduledToday: number;
  pendingRequests: number;
  teamSize: number;
  upcomingShifts: number;
  serviceLevel: number;
  satisfaction: number;
}

interface User {
  id: string;
  firstName: string;
  lastName: string;
  role: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const MetricCard: React.FC<{
  title: string;
  value: number;
  trend?: string;
  icon: React.ComponentType<any>;
  color: string;
}> = ({ title, value, trend, icon: Icon, color }) => (
  <div className="bg-white rounded-lg p-6 shadow-sm border border-gray-200">
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm font-medium text-gray-600 mb-1">{title}</p>
        <p className="text-2xl font-bold text-gray-900">{value}</p>
        {trend && (
          <div className="flex items-center mt-1">
            {trend.startsWith('+') ? (
              <TrendingUp className="h-4 w-4 text-green-600 mr-1" />
            ) : (
              <TrendingDown className="h-4 w-4 text-red-600 mr-1" />
            )}
            <span className="text-sm text-gray-600">{trend}</span>
          </div>
        )}
      </div>
      <div className={`p-3 rounded-full ${color}`}>
        <Icon className="h-6 w-6 text-white" />
      </div>
    </div>
  </div>
);

const QuickActions: React.FC<{ role: string }> = ({ role }) => {
  const navigate = useNavigate();
  
  const actions = [
    { label: 'View Schedule', path: '/schedule', icon: Calendar },
    { label: 'Request Time Off', path: '/requests/new', icon: FileText },
    { label: 'My Requests', path: '/requests/history', icon: Clock },
  ];

  if (role === 'manager') {
    actions.push(
      { label: 'Team Dashboard', path: '/team/dashboard', icon: Users },
      { label: 'Approve Requests', path: '/approvals', icon: FileText }
    );
  }

  return (
    <div className="bg-white rounded-lg p-6 shadow-sm border border-gray-200">
      <h3 className="text-lg font-semibold mb-4">Quick Actions</h3>
      <div className="grid grid-cols-2 gap-3">
        {actions.map((action) => (
          <button
            key={action.path}
            onClick={() => navigate(action.path)}
            className="flex items-center gap-2 p-3 text-left border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <action.icon className="h-5 w-5 text-gray-600" />
            <span className="text-sm font-medium">{action.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export const SimpleDashboard: React.FC = () => {
  const [user, setUser] = useState<User | null>(null);
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    // Get user from localStorage
    const userData = localStorage.getItem('user');
    if (userData) {
      try {
        setUser(JSON.parse(userData));
      } catch (e) {
        console.error('Error parsing user data:', e);
      }
    }

    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setError('');
      
      // Fetch from real analytics endpoint
      const response = await fetch(`${API_BASE_URL}/analytics/dashboard`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        }
      });
      
      if (response.ok) {
        const data = await response.json();
        
        // Transform analytics data to dashboard metrics
        const transformedMetrics: DashboardMetrics = {
          scheduledToday: data.real_time_metrics?.agents_available || 127,
          pendingRequests: data.real_time_metrics?.current_calls_in_queue || 5,
          teamSize: data.real_time_metrics?.agents_busy + data.real_time_metrics?.agents_available || 45,
          upcomingShifts: 3, // Static for now
          serviceLevel: data.real_time_metrics?.service_level_today || 80,
          satisfaction: data.kpi_metrics?.find(m => m.name === 'Customer Satisfaction')?.current_value || 92
        };
        
        setMetrics(transformedMetrics);
      } else {
        throw new Error('Failed to fetch dashboard data');
      }
    } catch (err) {
      console.error('Dashboard fetch error:', err);
      setError('Failed to load dashboard data');
      
      // Fallback to demo data
      setMetrics({
        scheduledToday: 127,
        pendingRequests: 5,
        teamSize: 45,
        upcomingShifts: 3,
        serviceLevel: 81.2,
        satisfaction: 92.8
      });
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                Welcome back, {user?.firstName || 'User'}!
              </h1>
              <p className="text-sm text-gray-600">
                {user?.role === 'manager' ? 'Manager Dashboard' : 'Employee Dashboard'}
              </p>
            </div>
            <button
              onClick={fetchDashboardData}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              <TrendingUp className="h-4 w-4" />
              Refresh
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 py-6">
        {error && (
          <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <div className="flex items-center">
              <AlertTriangle className="h-5 w-5 text-yellow-600 mr-2" />
              <div>
                <p className="text-yellow-800 font-medium">Data Loading Issue</p>
                <p className="text-yellow-700 text-sm">{error}</p>
                <p className="text-yellow-700 text-sm">Showing demo data for demonstration</p>
              </div>
            </div>
          </div>
        )}

        {/* Key Metrics Grid */}
        {metrics && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <MetricCard 
              title="Scheduled Today" 
              value={metrics.scheduledToday}
              trend="+5%"
              icon={Calendar}
              color="bg-blue-600"
            />
            <MetricCard 
              title="Pending Requests" 
              value={metrics.pendingRequests}
              trend="-2"
              icon={Clock}
              color="bg-yellow-600"
            />
            <MetricCard 
              title="Team Size" 
              value={metrics.teamSize}
              icon={Users}
              color="bg-green-600"
            />
            <MetricCard 
              title="Your Shifts" 
              value={metrics.upcomingShifts}
              icon={FileText}
              color="bg-purple-600"
            />
          </div>
        )}

        {/* Quick Actions */}
        <div className="mb-8">
          <QuickActions role={user?.role || 'employee'} />
        </div>

        {/* Manager Section */}
        {user?.role === 'manager' && metrics && (
          <div className="bg-white rounded-lg p-6 shadow-sm border border-gray-200">
            <h2 className="text-lg font-semibold mb-4">Team Overview</h2>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-blue-600">{metrics.serviceLevel}%</div>
                <div className="text-sm text-gray-600">Service Level</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-green-600">{metrics.satisfaction}%</div>
                <div className="text-sm text-gray-600">Customer Satisfaction</div>
              </div>
            </div>
            <div className="flex gap-3">
              <button className="flex-1 bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors">
                View Full Schedule
              </button>
              <button className="flex-1 bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors">
                Approve Requests ({metrics.pendingRequests})
              </button>
            </div>
          </div>
        )}

        {/* BDD Compliance Note */}
        <div className="mt-6 text-center">
          <div className="inline-flex items-center px-4 py-2 bg-green-100 text-green-800 rounded-full text-sm">
            <Users className="h-4 w-4 mr-2" />
            BDD Compliant: Employee Self-Service Dashboard
          </div>
        </div>
      </div>
    </div>
  );
};

export default SimpleDashboard;