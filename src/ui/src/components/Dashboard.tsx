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
  LogOut
} from 'lucide-react';
import { metricsAPI } from '../services/api';

const Dashboard: React.FC = () => {
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [metrics, setMetrics] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  
  // Load initial metrics
  useEffect(() => {
    loadMetrics();
  }, []);
  
  const loadMetrics = async () => {
    try {
      const data = await metricsAPI.getDashboardMetrics();
      setMetrics(data);
    } catch (error) {
      console.warn('Using mock metrics');
    } finally {
      setIsLoading(false);
    }
  };

  // 30-second real-time update pattern
  useEffect(() => {
    const interval = setInterval(async () => {
      setIsUpdating(true);
      await loadMetrics();
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  // Format metrics for display
  const displayMetrics = metrics ? [
    {
      title: 'Active Agents',
      value: metrics.activeAgents?.toString() || '127',
      icon: Users,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100'
    },
    {
      title: 'Service Level',
      value: `${metrics.serviceLevel || 94.2}%`,
      icon: TrendingUp,
      color: 'text-green-600',
      bgColor: 'bg-green-100'
    },
    {
      title: 'Calls Handled',
      value: metrics.callsHandled?.toLocaleString() || '3,847',
      icon: Phone,
      color: 'text-purple-600',
      bgColor: 'bg-purple-100'
    },
    {
      title: 'Average Wait Time',
      value: metrics.avgWaitTime || '0:45',
      icon: Clock,
      color: 'text-orange-600',
      bgColor: 'bg-orange-100'
    }
  ] : [];
  
  const handleLogout = () => {
    localStorage.removeItem('authToken');
    window.location.href = '/login';
  };

  const moduleLinks = [
    {
      title: 'Schedule Management',
      description: 'Manage agent schedules and shifts',
      icon: Calendar,
      path: '/schedule',
      color: 'bg-blue-500'
    },
    {
      title: 'Forecasting Analytics',
      description: 'Predict call volumes and staffing needs',
      icon: TrendingUp,
      path: '/forecasting',
      color: 'bg-green-500'
    },
    {
      title: 'Reports & Analytics',
      description: 'View performance reports and KPIs',
      icon: BarChart3,
      path: '/reports',
      color: 'bg-purple-500'
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <h1 className="text-3xl font-bold text-gray-900">WFM Dashboard</h1>
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
        {/* Metrics Grid */}
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

        {/* Module Links */}
        <div className="mb-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Quick Access</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {moduleLinks.map((module) => {
              const Icon = module.icon;
              return (
                <Link
                  key={module.path}
                  to={module.path}
                  className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow p-6 block"
                >
                  <div className="flex items-center mb-4">
                    <div className={`${module.color} rounded-lg p-3`}>
                      <Icon className="h-6 w-6 text-white" />
                    </div>
                    <h3 className="ml-4 text-lg font-semibold text-gray-900">
                      {module.title}
                    </h3>
                  </div>
                  <p className="text-gray-600">{module.description}</p>
                  <div className="mt-4 text-blue-600 font-medium">
                    Open Module →
                  </div>
                </Link>
              );
            })}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Today's Performance</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <p className="text-sm text-gray-600">Peak Hour</p>
              <p className="text-lg font-semibold">14:00 - 15:00</p>
              <p className="text-sm text-gray-500">189 calls handled</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Agent Utilization</p>
              <p className="text-lg font-semibold">{metrics?.utilization || 87.3}%</p>
              <p className="text-sm text-green-600">↑ 3.2% from yesterday</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Customer Satisfaction</p>
              <p className="text-lg font-semibold">{metrics?.satisfaction || 4.3}/5.0</p>
              <p className="text-sm text-gray-500">Based on 247 surveys</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;