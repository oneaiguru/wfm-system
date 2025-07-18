import React from 'react';
import { Calendar, FileText, Clock, User, Bell, TrendingUp } from 'lucide-react';

export const EmployeeDashboard: React.FC = () => {
  // Demo data - would come from API after login
  const employee = {
    name: "John Doe",
    daysOffRemaining: 15,
    upcomingShifts: 5,
    pendingRequests: 2
  };

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
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                Welcome back, {employee.name}!
              </h1>
              <p className="text-gray-600">Here's your dashboard for today</p>
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
            value={employee.daysOffRemaining}
            icon={Calendar}
            color="bg-green-600"
          />
          <QuickStatCard
            title="Upcoming Shifts"
            value={employee.upcomingShifts}
            icon={Clock}
            color="bg-blue-600"
          />
          <QuickStatCard
            title="Pending Requests"
            value={employee.pendingRequests}
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
      </div>
    </div>
  );
};

export default EmployeeDashboard;