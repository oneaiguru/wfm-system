import React from 'react';
import { 
  Clock, 
  Calendar, 
  TrendingUp, 
  Award,
  AlertCircle,
  ChevronRight
} from 'lucide-react';

// BDD: Mobile dashboard should provide key metric dashboard with essential metrics only
const MobileDashboard: React.FC = () => {
  // Mock data - would come from API
  const todayShift = {
    start: '09:00',
    end: '18:00',
    break: '13:00-14:00',
    status: 'scheduled'
  };

  const metrics = {
    hoursThisWeek: 32,
    efficiency: 94.5,
    requestsPending: 2,
    nextVacation: '15.08.2024'
  };

  const quickActions = [
    { label: 'Запросить выходной', icon: Calendar, color: 'bg-blue-500' },
    { label: 'Обменять смену', icon: Clock, color: 'bg-green-500' },
    { label: 'Посмотреть KPI', icon: TrendingUp, color: 'bg-purple-500' }
  ];

  return (
    <div className="space-y-6">
      {/* Today's Schedule Card */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Сегодняшняя смена</h2>
        <div className="flex items-center justify-between">
          <div>
            <p className="text-2xl font-bold text-blue-600">
              {todayShift.start} - {todayShift.end}
            </p>
            <p className="text-sm text-gray-600 mt-1">Перерыв: {todayShift.break}</p>
          </div>
          <div className="text-right">
            <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
              Запланировано
            </span>
          </div>
        </div>
      </div>

      {/* Key Metrics Grid */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-lg shadow-sm p-4">
          <div className="flex items-center justify-between mb-2">
            <Clock className="h-5 w-5 text-blue-600" />
            <span className="text-xs text-gray-500">Эта неделя</span>
          </div>
          <p className="text-2xl font-bold text-gray-900">{metrics.hoursThisWeek}ч</p>
          <p className="text-sm text-gray-600">Отработано</p>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-4">
          <div className="flex items-center justify-between mb-2">
            <Award className="h-5 w-5 text-green-600" />
            <span className="text-xs text-gray-500">KPI</span>
          </div>
          <p className="text-2xl font-bold text-gray-900">{metrics.efficiency}%</p>
          <p className="text-sm text-gray-600">Эффективность</p>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-4">
          <div className="flex items-center justify-between mb-2">
            <AlertCircle className="h-5 w-5 text-yellow-600" />
            <span className="text-xs text-gray-500">Ожидают</span>
          </div>
          <p className="text-2xl font-bold text-gray-900">{metrics.requestsPending}</p>
          <p className="text-sm text-gray-600">Заявки</p>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-4">
          <div className="flex items-center justify-between mb-2">
            <Calendar className="h-5 w-5 text-purple-600" />
            <span className="text-xs text-gray-500">Отпуск</span>
          </div>
          <p className="text-lg font-bold text-gray-900">{metrics.nextVacation}</p>
          <p className="text-sm text-gray-600">Следующий</p>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Быстрые действия</h3>
        <div className="space-y-3">
          {quickActions.map((action, index) => {
            const Icon = action.icon;
            return (
              <button
                key={index}
                className="w-full flex items-center justify-between p-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center space-x-3">
                  <div className={`p-2 rounded-lg ${action.color}`}>
                    <Icon className="h-5 w-5 text-white" />
                  </div>
                  <span className="font-medium text-gray-900">{action.label}</span>
                </div>
                <ChevronRight className="h-5 w-5 text-gray-400" />
              </button>
            );
          })}
        </div>
      </div>

      {/* Upcoming Schedule Preview */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Ближайшие смены</h3>
        <div className="space-y-3">
          <div className="flex items-center justify-between py-2">
            <div>
              <p className="font-medium text-gray-900">Пн, 12 июля</p>
              <p className="text-sm text-gray-600">09:00 - 18:00</p>
            </div>
            <span className="text-sm text-gray-500">Дневная</span>
          </div>
          <div className="flex items-center justify-between py-2">
            <div>
              <p className="font-medium text-gray-900">Вт, 13 июля</p>
              <p className="text-sm text-gray-600">09:00 - 18:00</p>
            </div>
            <span className="text-sm text-gray-500">Дневная</span>
          </div>
          <div className="flex items-center justify-between py-2">
            <div>
              <p className="font-medium text-gray-900">Ср, 14 июля</p>
              <p className="text-sm text-gray-600">Выходной</p>
            </div>
            <span className="text-sm text-green-600">Отдых</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MobileDashboard;