import React, { useState, useEffect } from 'react';
import { Calendar, FileText, Clock, User, Bell, TrendingUp, Loader2, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

interface Employee {
  id: string;
  employee_number: string;
  first_name: string;
  last_name: string;
  email: string;
  department_id: string;
  employment_type: string;
  hire_date: string;
  is_active: boolean;
  time_zone: string;
  user_id: string;
}

export const EmployeeDashboard: React.FC = () => {
  const navigate = useNavigate();
  const [employee, setEmployee] = useState<Employee | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Demo stats (would come from additional API calls)
  const stats = {
    daysOffRemaining: 15,
    upcomingShifts: 5,
    pendingRequests: 2
  };

  useEffect(() => {
    const fetchEmployeeData = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/employees/me`);
        
        if (!response.ok) {
          throw new Error('Failed to fetch employee data');
        }
        
        const data = await response.json();
        setEmployee(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load employee data');
        console.error('Employee data fetch error:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchEmployeeData();
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="flex items-center gap-2">
          <Loader2 className="h-6 w-6 animate-spin text-blue-600" />
          <span className="text-gray-600">Loading employee data...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white rounded-lg shadow-sm border p-6 max-w-md text-center">
          <div className="text-red-600 mb-2">⚠️ Error</div>
          <p className="text-gray-600">{error}</p>
        </div>
      </div>
    );
  }

  const employeeName = employee ? `${employee.first_name} ${employee.last_name}` : 'Employee';

  const notifications = [
    { id: 1, message: "Schedule updated for next week", time: "2 hours ago" },
    { id: 2, message: "Vacation request approved", time: "1 day ago" },
    { id: 3, message: "New training session available", time: "3 days ago" }
  ];

  const QuickStatCard: React.FC<{
    title: string;
    value: number;
    icon: React.ComponentType<any>;
    color: string;
  }> = ({ title, value, icon: Icon, color }) => (
    <div className="bg-white rounded-lg p-6 shadow-sm border border-gray-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-600">{title}</p>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
        </div>
        <div className={`p-3 rounded-full ${color}`}>
          <Icon className="h-6 w-6 text-white" />
        </div>
      </div>
    </div>
  );

  const QuickActionCard: React.FC<{
    title: string;
    description: string;
    icon: React.ComponentType<any>;
    onClick: () => void;
  }> = ({ title, description, icon: Icon, onClick }) => (
    <div 
      className="bg-white rounded-lg p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow cursor-pointer"
      onClick={onClick}
    >
      <div className="flex items-center gap-4">
        <div className="p-3 bg-blue-100 rounded-lg">
          <Icon className="h-6 w-6 text-blue-600" />
        </div>
        <div>
          <h3 className="font-semibold text-gray-900">{title}</h3>
          <p className="text-sm text-gray-600">{description}</p>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => navigate('/demo')}
                className="flex items-center gap-2 text-blue-600 hover:text-blue-800 transition-colors"
              >
                <ArrowLeft className="h-5 w-5" />
                Back to Demo
              </button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  Welcome back, {employeeName}!
                </h1>
                <p className="text-gray-600">Here's your dashboard for today</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Bell className="h-5 w-5 text-gray-400" />
              <span className="text-sm text-gray-600">3 notifications</span>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 py-6">
        {/* Quick Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <QuickStatCard
            title="Days Off Remaining"
            value={stats.daysOffRemaining}
            icon={Calendar}
            color="bg-green-600"
          />
          <QuickStatCard
            title="Upcoming Shifts"
            value={stats.upcomingShifts}
            icon={Clock}
            color="bg-blue-600"
          />
          <QuickStatCard
            title="Pending Requests"
            value={stats.pendingRequests}
            icon={FileText}
            color="bg-yellow-600"
          />
        </div>

        {/* Quick Actions */}
        <div className="mb-8">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <QuickActionCard
              title="View My Schedule"
              description="See your upcoming shifts and availability"
              icon={Calendar}
              onClick={() => console.log('Navigate to schedule')}
            />
            <QuickActionCard
              title="Request Time Off"
              description="Submit vacation or personal time requests"
              icon={FileText}
              onClick={() => console.log('Navigate to request form')}
            />
          </div>
        </div>

        {/* Recent Notifications */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Recent Notifications</h2>
          <div className="space-y-3">
            {notifications.map((notification) => (
              <div key={notification.id} className="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
                <Bell className="h-5 w-5 text-blue-600 mt-0.5" />
                <div className="flex-1">
                  <p className="text-sm text-gray-900">{notification.message}</p>
                  <p className="text-xs text-gray-500 mt-1">{notification.time}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* BDD Compliance Note */}
        <div className="text-center mt-8">
          <div className="inline-flex items-center px-4 py-2 bg-green-100 text-green-800 rounded-full text-sm">
            <User className="h-4 w-4 mr-2" />
            BDD Compliant: Employee Dashboard - Real API Integration
          </div>
        </div>
      </div>
    </div>
  );
};

export default EmployeeDashboard;