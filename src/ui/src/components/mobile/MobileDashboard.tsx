import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { 
  Calendar, Clock, CheckCircle, AlertCircle, 
  Home, FileText, Bell, User 
} from 'lucide-react';

interface DashboardStats {
  todayShifts: number;
  upcomingRequests: number;
  unreadNotifications: number;
  totalHoursThisWeek: number;
}

export const MobileDashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats>({
    todayShifts: 1,
    upcomingRequests: 2,
    unreadNotifications: 3,
    totalHoursThisWeek: 32
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // Load dashboard data
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      // TODO: Load real data from API
      // const data = await mobileService.getDashboardStats();
      // setStats(data);
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const quickActions = [
    {
      title: 'Мой График',
      icon: Calendar,
      path: '/mobile/schedule',
      color: 'bg-blue-500'
    },
    {
      title: 'Новый Запрос',
      icon: FileText,
      path: '/mobile/requests/new',
      color: 'bg-green-500'
    },
    {
      title: 'Уведомления',
      icon: Bell,
      path: '/mobile/notifications',
      color: 'bg-purple-500',
      badge: stats.unreadNotifications
    },
    {
      title: 'Профиль',
      icon: User,
      path: '/mobile/profile',
      color: 'bg-gray-500'
    }
  ];

  return (
    <div data-testid="mobile-dashboard" className="mobile-dashboard min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="px-4 py-6">
          <h1 className="text-2xl font-bold text-gray-900">Мобильная Панель</h1>
          <p className="text-sm text-gray-600 mt-1">Добро пожаловать!</p>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="p-4">
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="bg-white rounded-lg p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <Clock className="h-8 w-8 text-blue-500" />
              <span className="text-2xl font-bold">{stats.todayShifts}</span>
            </div>
            <p className="text-sm text-gray-600 mt-2">Смен сегодня</p>
          </div>

          <div className="bg-white rounded-lg p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <FileText className="h-8 w-8 text-green-500" />
              <span className="text-2xl font-bold">{stats.upcomingRequests}</span>
            </div>
            <p className="text-sm text-gray-600 mt-2">Активных запросов</p>
          </div>

          <div className="bg-white rounded-lg p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <Bell className="h-8 w-8 text-purple-500" />
              <span className="text-2xl font-bold">{stats.unreadNotifications}</span>
            </div>
            <p className="text-sm text-gray-600 mt-2">Новых уведомлений</p>
          </div>

          <div className="bg-white rounded-lg p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <CheckCircle className="h-8 w-8 text-orange-500" />
              <span className="text-2xl font-bold">{stats.totalHoursThisWeek}</span>
            </div>
            <p className="text-sm text-gray-600 mt-2">Часов на неделе</p>
          </div>
        </div>

        {/* Quick Actions */}
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Быстрые действия</h2>
        <div className="grid grid-cols-2 gap-4">
          {quickActions.map((action) => {
            const Icon = action.icon;
            return (
              <Link
                key={action.path}
                to={action.path}
                className="bg-white rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow relative"
              >
                <div className={`${action.color} rounded-lg p-3 inline-flex mb-3`}>
                  <Icon className="h-6 w-6 text-white" />
                </div>
                {action.badge && action.badge > 0 && (
                  <span className="absolute top-2 right-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                    {action.badge}
                  </span>
                )}
                <h3 className="font-medium text-gray-900">{action.title}</h3>
              </Link>
            );
          })}
        </div>

        {/* Today's Schedule Preview */}
        <div className="mt-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Сегодняшний график</h2>
          <div className="bg-white rounded-lg shadow-sm p-4">
            {stats.todayShifts > 0 ? (
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-900">08:00 - 17:00</p>
                  <p className="text-sm text-gray-600">Обслуживание клиентов</p>
                </div>
                <CheckCircle className="h-5 w-5 text-green-500" />
              </div>
            ) : (
              <p className="text-gray-500 text-center py-4">Сегодня выходной</p>
            )}
          </div>
        </div>

        {/* Recent Activity */}
        <div className="mt-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Последняя активность</h2>
          <div className="bg-white rounded-lg shadow-sm">
            <div className="divide-y divide-gray-200">
              <div className="p-4 flex items-center">
                <CheckCircle className="h-5 w-5 text-green-500 mr-3" />
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">Запрос одобрен</p>
                  <p className="text-xs text-gray-500">Отпуск 15-20 августа</p>
                </div>
              </div>
              <div className="p-4 flex items-center">
                <AlertCircle className="h-5 w-5 text-yellow-500 mr-3" />
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">Изменение графика</p>
                  <p className="text-xs text-gray-500">Смена перенесена на 25 июля</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200">
        <div className="grid grid-cols-4">
          <Link to="/mobile/dashboard" className="py-3 text-center text-blue-600">
            <Home className="h-6 w-6 mx-auto" />
            <span className="text-xs mt-1 block">Главная</span>
          </Link>
          <Link to="/mobile/schedule" className="py-3 text-center text-gray-600">
            <Calendar className="h-6 w-6 mx-auto" />
            <span className="text-xs mt-1 block">График</span>
          </Link>
          <Link to="/mobile/requests" className="py-3 text-center text-gray-600">
            <FileText className="h-6 w-6 mx-auto" />
            <span className="text-xs mt-1 block">Запросы</span>
          </Link>
          <Link to="/mobile/profile" className="py-3 text-center text-gray-600">
            <User className="h-6 w-6 mx-auto" />
            <span className="text-xs mt-1 block">Профиль</span>
          </Link>
        </div>
      </div>
    </div>
  );
};

export default MobileDashboard;