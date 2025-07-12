import React, { useState } from 'react';

// Employee Portal Layout Component
// Professional employee self-service interface structure

interface EmployeeLayoutProps {
  children: React.ReactNode;
  currentView?: string;
  onViewChange?: (view: string) => void;
}

interface User {
  id: string;
  name: string;
  position: string;
  avatar?: string;
  team: string;
}

interface MenuItem {
  id: string;
  label: string;
  icon: string;
  path: string;
  active?: boolean;
}

interface Notification {
  id: string;
  title: string;
  message: string;
  time: string;
  type: 'schedule' | 'request' | 'exchange' | 'system';
  read: boolean;
}

const EmployeeLayout: React.FC<EmployeeLayoutProps> = ({ children, currentView = 'dashboard', onViewChange }) => {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  // Mock user data
  const user: User = {
    id: '1',
    name: 'John Smith',
    position: 'Customer Service Agent',
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=40&h=40&fit=crop&crop=face',
    team: 'Customer Support'
  };

  // Navigation menu items (matching employee portal structure)
  const menuItems: MenuItem[] = [
    { id: 'dashboard', label: 'Dashboard', icon: '🏠', path: '/employee/dashboard', active: currentView === 'dashboard' },
    { id: 'schedule', label: 'My Schedule', icon: '📅', path: '/employee/schedule', active: currentView === 'schedule' },
    { id: 'requests', label: 'Requests', icon: '📝', path: '/employee/requests', active: currentView === 'requests' },
    { id: 'marketplace', label: 'Shift Exchange', icon: '🔄', path: '/employee/marketplace', active: currentView === 'marketplace' },
    { id: 'profile', label: 'Profile', icon: '👤', path: '/employee/profile', active: currentView === 'profile' },
  ];

  // Mock notifications
  const notifications: Notification[] = [
    {
      id: '1',
      title: 'Schedule Change',
      message: 'Your shift tomorrow has been moved from 08:00 to 09:00',
      time: '30 min ago',
      type: 'schedule',
      read: false
    },
    {
      id: '2',
      title: 'Request Approved',
      message: 'Your vacation request has been approved',
      time: '2 hours ago',
      type: 'request',
      read: false
    },
    {
      id: '3',
      title: 'Shift Exchange',
      message: 'Peter Johnson wants to exchange shifts with you',
      time: '4 hours ago',
      type: 'exchange',
      read: true
    }
  ];

  const unreadCount = notifications.filter(n => !n.read).length;

  const handleMenuClick = (menuId: string) => {
    setLoading(true);
    onViewChange?.(menuId);
    // Simulate navigation
    setTimeout(() => setLoading(false), 300);
  };

  const handleLogout = () => {
    if (window.confirm('Are you sure you want to logout?')) {
      // Handle logout
      console.log('Logout');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      {/* Sidebar */}
      <div className={`bg-slate-800 text-white transition-all duration-300 ${
        sidebarCollapsed ? 'w-16' : 'w-64'
      } flex flex-col`}>
        
        {/* Logo/Header */}
        <div className="p-4 border-b border-slate-700">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-blue-500 rounded flex items-center justify-center">
              <span className="text-white font-bold text-sm">WFM</span>
            </div>
            {!sidebarCollapsed && (
              <div>
                <h1 className="text-lg font-semibold">WFM Portal</h1>
                <p className="text-xs text-slate-300">Employee</p>
              </div>
            )}
          </div>
          
          {/* Collapse button */}
          <button
            onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
            className="absolute top-4 -right-3 w-6 h-6 bg-slate-700 rounded-full flex items-center justify-center text-slate-300 hover:text-white hover:bg-slate-600"
          >
            {sidebarCollapsed ? '→' : '←'}
          </button>
        </div>

        {/* Navigation Menu */}
        <nav className="flex-1 p-4">
          <ul className="space-y-2">
            {menuItems.map((item) => (
              <li key={item.id}>
                <button
                  onClick={() => handleMenuClick(item.id)}
                  className={`w-full flex items-center gap-3 px-3 py-3 rounded-lg transition-colors text-left ${
                    item.active 
                      ? 'bg-blue-600 text-white' 
                      : 'text-slate-300 hover:text-white hover:bg-slate-700'
                  }`}
                  title={sidebarCollapsed ? item.label : ''}
                >
                  <span className="text-xl flex-shrink-0">{item.icon}</span>
                  {!sidebarCollapsed && (
                    <span className="font-medium">{item.label}</span>
                  )}
                </button>
              </li>
            ))}
          </ul>
        </nav>

        {/* User Section */}
        <div className="p-4 border-t border-slate-700">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-blue-500 rounded-full overflow-hidden flex-shrink-0">
              {user.avatar ? (
                <img src={user.avatar} alt={user.name} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-white font-bold">
                  {user.name.charAt(0)}
                </div>
              )}
            </div>
            {!sidebarCollapsed && (
              <div className="min-w-0">
                <p className="font-medium text-white truncate">{user.name}</p>
                <p className="text-xs text-slate-400 truncate">{user.position}</p>
              </div>
            )}
          </div>
          
          {!sidebarCollapsed && (
            <button
              onClick={handleLogout}
              className="w-full flex items-center gap-2 px-3 py-2 text-slate-300 hover:text-white hover:bg-slate-700 rounded-lg transition-colors"
            >
              <span>🚪</span>
              <span>Logout</span>
            </button>
          )}
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col">
        
        {/* Header */}
        <header className="bg-white border-b border-gray-200 px-6 py-4">
          <div className="flex items-center justify-between">
            
            {/* Page Title & Breadcrumbs */}
            <div>
              <h2 className="text-xl font-semibold text-gray-900">Dashboard</h2>
              <p className="text-sm text-gray-500 mt-1">Welcome to your personal workspace</p>
            </div>

            {/* Header Actions */}
            <div className="flex items-center gap-4">
              
              {/* Notifications */}
              <div className="relative">
                <button
                  onClick={() => setNotificationsOpen(!notificationsOpen)}
                  className="relative p-2 text-gray-400 hover:text-gray-600 transition-colors"
                >
                  <span className="text-xl">🔔</span>
                  {unreadCount > 0 && (
                    <span className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">
                      {unreadCount}
                    </span>
                  )}
                </button>

                {/* Notifications Dropdown */}
                {notificationsOpen && (
                  <>
                    <div 
                      className="fixed inset-0 z-10" 
                      onClick={() => setNotificationsOpen(false)}
                    />
                    <div className="absolute right-0 top-12 w-80 bg-white rounded-lg shadow-xl border border-gray-200 z-20">
                      <div className="p-4 border-b border-gray-200">
                        <h3 className="font-semibold text-gray-900">Notifications</h3>
                      </div>
                      <div className="max-h-64 overflow-y-auto">
                        {notifications.map((notification) => (
                          <div
                            key={notification.id}
                            className={`p-4 border-b border-gray-100 last:border-b-0 hover:bg-gray-50 ${
                              !notification.read ? 'bg-blue-50' : ''
                            }`}
                          >
                            <div className="flex justify-between items-start gap-2">
                              <div className="flex-1">
                                <h4 className={`text-sm ${!notification.read ? 'font-semibold' : 'font-medium'}`}>
                                  {notification.title}
                                </h4>
                                <p className="text-sm text-gray-600 mt-1">{notification.message}</p>
                                <p className="text-xs text-gray-500 mt-2">{notification.time}</p>
                              </div>
                              {!notification.read && (
                                <div className="w-2 h-2 bg-blue-500 rounded-full flex-shrink-0 mt-1"></div>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                      <div className="p-3 border-t border-gray-200">
                        <button className="w-full text-sm text-blue-600 hover:text-blue-800">
                          View All
                        </button>
                      </div>
                    </div>
                  </>
                )}
              </div>

              {/* Quick Actions */}
              <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors" title="Settings">
                <span className="text-xl">⚙️</span>
              </button>

              {/* User Menu */}
              <div className="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="w-8 h-8 bg-blue-500 rounded-full overflow-hidden">
                  {user.avatar ? (
                    <img src={user.avatar} alt={user.name} className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-white font-bold text-sm">
                      {user.name.charAt(0)}
                    </div>
                  )}
                </div>
                <div className="text-sm">
                  <p className="font-medium text-gray-900">{user.name}</p>
                  <p className="text-gray-500">{user.position}</p>
                </div>
              </div>
            </div>
          </div>
        </header>

        {/* Main Content Area */}
        <main className="flex-1 overflow-auto">
          {loading ? (
            <div className="flex items-center justify-center h-64">
              <div className="flex flex-col items-center gap-4">
                <div className="w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
                <p className="text-gray-600">Loading...</p>
              </div>
            </div>
          ) : (
            children
          )}
        </main>
      </div>
    </div>
  );
};

export default EmployeeLayout;