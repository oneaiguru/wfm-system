import React, { useState, useEffect } from 'react';
import { 
  Calendar, 
  FileText, 
  Bell, 
  User, 
  Home,
  Menu,
  X,
  Settings,
  LogOut
} from 'lucide-react';
import MobileDashboard from './dashboard/MobileDashboard';
import MobileCalendar from './calendar/MobileCalendar';
import MobileRequests from './requests/MobileRequests';
import MobileNotifications from './notifications/MobileNotifications';
import MobileProfile from './profile/MobileProfile';
import { useMobileAuth } from '../hooks/useMobileAuth';
import { useOfflineSync } from '../hooks/useOfflineSync';

// BDD: Feature: Mobile personal cabinet
// Scenario: Employee accesses personal cabinet on mobile device
const MobilePersonalCabinet: React.FC = () => {
  const [currentView, setCurrentView] = useState('dashboard');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const { user, logout } = useMobileAuth();
  const { isOffline, syncStatus } = useOfflineSync();

  // Mobile viewport detection
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth > 768) {
        setIsSidebarOpen(true);
      } else {
        setIsSidebarOpen(false);
      }
    };
    
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  const navigationItems = [
    { id: 'dashboard', label: 'Главная', icon: Home },
    { id: 'calendar', label: 'Календарь', icon: Calendar },
    { id: 'requests', label: 'Заявки', icon: FileText },
    { id: 'notifications', label: 'Уведомления', icon: Bell },
    { id: 'profile', label: 'Профиль', icon: User }
  ];

  const handleNavigation = (viewId: string) => {
    setCurrentView(viewId);
    if (window.innerWidth <= 768) {
      setIsSidebarOpen(false);
    }
  };

  const renderContent = () => {
    switch (currentView) {
      case 'dashboard':
        return <MobileDashboard />;
      case 'calendar':
        return <MobileCalendar />;
      case 'requests':
        return <MobileRequests />;
      case 'notifications':
        return <MobileNotifications />;
      case 'profile':
        return <MobileProfile />;
      default:
        return <MobileDashboard />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col md:flex-row">
      {/* Mobile Header */}
      <div className="md:hidden bg-white shadow-sm px-4 py-3 flex items-center justify-between">
        <button
          onClick={() => setIsSidebarOpen(!isSidebarOpen)}
          className="p-2 hover:bg-gray-100 rounded-lg"
        >
          {isSidebarOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
        <h1 className="text-lg font-semibold">Личный кабинет</h1>
        <div className="flex items-center space-x-2">
          {isOffline && (
            <div className="w-2 h-2 bg-yellow-500 rounded-full" title="Offline mode" />
          )}
          <Settings className="h-5 w-5 text-gray-600" />
        </div>
      </div>

      {/* Sidebar Navigation */}
      <div className={`
        ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}
        md:translate-x-0 fixed md:relative z-40 w-64 h-full bg-white shadow-lg
        transition-transform duration-300 ease-in-out
      `}>
        <div className="p-6 border-b">
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-blue-600 rounded-full flex items-center justify-center text-white font-semibold">
              {user?.name?.split(' ').map(n => n[0]).join('')}
            </div>
            <div>
              <p className="font-semibold text-gray-900">{user?.name || 'Сотрудник'}</p>
              <p className="text-sm text-gray-600">{user?.role || 'Агент'}</p>
            </div>
          </div>
        </div>

        <nav className="p-4">
          {navigationItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                onClick={() => handleNavigation(item.id)}
                className={`
                  w-full flex items-center space-x-3 px-4 py-3 rounded-lg
                  transition-colors duration-200
                  ${currentView === item.id 
                    ? 'bg-blue-50 text-blue-600' 
                    : 'text-gray-700 hover:bg-gray-50'
                  }
                `}
              >
                <Icon className="h-5 w-5" />
                <span className="font-medium">{item.label}</span>
              </button>
            );
          })}
        </nav>

        <div className="absolute bottom-0 w-full p-4 border-t">
          <button
            onClick={logout}
            className="w-full flex items-center space-x-3 px-4 py-3 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          >
            <LogOut className="h-5 w-5" />
            <span className="font-medium">Выйти</span>
          </button>
        </div>
      </div>

      {/* Overlay for mobile */}
      {isSidebarOpen && (
        <div 
          className="md:hidden fixed inset-0 bg-black bg-opacity-50 z-30"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        <div className="p-4 md:p-6">
          {/* Sync Status Bar */}
          {syncStatus && (
            <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg flex items-center justify-between">
              <span className="text-sm text-blue-700">{syncStatus}</span>
              {isOffline && (
                <span className="text-xs text-blue-600">Работа в офлайн режиме</span>
              )}
            </div>
          )}
          
          {renderContent()}
        </div>
      </div>
    </div>
  );
};

export default MobilePersonalCabinet;