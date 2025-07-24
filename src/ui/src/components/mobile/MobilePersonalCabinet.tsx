import React, { useState, useEffect } from 'react';
import { 
  User, Calendar, Clock, Bell, Settings, LogOut, Fingerprint, 
  Shield, ChevronRight, Plus, Check, RefreshCw, Wifi, WifiOff,
  Heart, FileText, CalendarDays, Users, Home, Menu, X
} from 'lucide-react';

interface BiometricStatus {
  enabled: boolean;
  available_methods: ('fingerprint' | 'face_id' | 'touch_id')[];
  last_setup: string;
  setup_required: boolean;
}

interface MobileDashboardData {
  employee: {
    id: number;
    name: string;
    position: string;
    avatar_url?: string;
    employee_code: string;
  };
  today_schedule: {
    shift_start?: string;
    shift_end?: string;
    break_start?: string;
    break_end?: string;
    status: 'scheduled' | 'in_progress' | 'break' | 'completed' | 'off';
  };
  requests: {
    pending: number;
    approved: number;
    rejected: number;
    total: number;
  };
  notifications: {
    unread: number;
    urgent: number;
    last_check: string;
  };
  biometric: BiometricStatus;
  offline_sync: {
    pending_changes: number;
    last_sync: string;
    connection_status: 'online' | 'offline' | 'syncing';
  };
}

interface MobileNotification {
  id: string;
  type: 'approval' | 'schedule' | 'system' | 'urgent';
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
  action_required: boolean;
}

// Russian translations for mobile interface
const mobileTranslations = {
  dashboard: {
    title: 'Личный Кабинет',
    subtitle: 'Мобильный портал сотрудника',
    greeting: (name: string) => `Добро пожаловать, ${name}`,
    sections: {
      calendar: 'Календарь',
      requests: 'Заявки', 
      notifications: 'Уведомления',
      profile: 'Профиль'
    }
  },
  schedule: {
    today: 'Сегодня',
    shiftStart: 'Начало смены',
    shiftEnd: 'Конец смены',
    breakTime: 'Перерыв',
    status: {
      scheduled: 'Запланировано',
      in_progress: 'В работе',
      break: 'Перерыв',
      completed: 'Завершено',
      off: 'Выходной'
    }
  },
  requests: {
    pending: 'Ожидают',
    approved: 'Одобрено',
    rejected: 'Отклонено',
    createNew: 'Создать заявку',
    types: {
      больничный: 'Больничный',
      отгул: 'Отгул',
      отпуск: 'Отпуск'
    }
  },
  biometric: {
    title: 'Биометрическая аутентификация',
    enabled: 'Включена',
    disabled: 'Отключена',
    setup: 'Настроить биометрию',
    methods: {
      fingerprint: 'Отпечаток пальца',
      face_id: 'Face ID',
      touch_id: 'Touch ID'
    }
  },
  sync: {
    online: 'Онлайн',
    offline: 'Автономный режим',
    syncing: 'Синхронизация',
    pendingChanges: (count: number) => `${count} изменений для синхронизации`,
    lastSync: 'Последняя синхронизация'
  },
  actions: {
    refresh: 'Обновить',
    settings: 'Настройки',
    logout: 'Выход',
    setupBiometric: 'Настроить биометрию',
    viewAll: 'Показать все'
  }
};

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

export const MobilePersonalCabinet: React.FC = () => {
  const [activeSection, setActiveSection] = useState<'dashboard' | 'calendar' | 'requests' | 'notifications' | 'profile'>('dashboard');
  const [dashboardData, setDashboardData] = useState<MobileDashboardData | null>(null);
  const [notifications, setNotifications] = useState<MobileNotification[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string>('');
  const [menuOpen, setMenuOpen] = useState(false);
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    loadMobileDashboard();
    
    // Listen for online/offline events
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  const loadMobileDashboard = async () => {
    if (dashboardData) setRefreshing(true);
    else setLoading(true);
    
    setError('');
    
    try {
      // Try SPEC-07 formal mobile endpoints (I-stage complete with working APIs)
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/mobile/cabinet/dashboard`, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data: MobileDashboardData = await response.json();
        setDashboardData(data);
        
        // Load mobile notifications
        const notificationsResponse = await fetch(`${API_BASE_URL}/mobile/cabinet/notifications`, {
          headers: { 'Authorization': `Bearer ${authToken}` }
        });
        
        if (notificationsResponse.ok) {
          const notifData = await notificationsResponse.json();
          setNotifications(notifData.notifications || []);
        }
        
        console.log('✅ SPEC-07 mobile cabinet dashboard loaded:', data);
      } else {
        // Use comprehensive demo data for SPEC-07 mobile cabinet
        console.log('⚠️ SPEC-07 mobile APIs not available, using demo data');
        setDashboardData(generateMobileDemoData());
        setNotifications(generateMobileDemoNotifications());
        setError('Демо данные - SPEC-07 mobile APIs в разработке');
      }
    } catch (err) {
      console.log('⚠️ Mobile cabinet API error, using demo data');
      setDashboardData(generateMobileDemoData());
      setNotifications(generateMobileDemoNotifications());
      setError('Сетевая ошибка - использование демо данных');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const generateMobileDemoData = (): MobileDashboardData => {
    return {
      employee: {
        id: 111538,
        name: 'Алексей Мобильный',
        position: 'Старший инженер',
        employee_code: 'EMP-111538',
        avatar_url: '/api/placeholder/64/64'
      },
      today_schedule: {
        shift_start: '09:00',
        shift_end: '18:00',
        break_start: '13:00',
        break_end: '14:00',
        status: 'in_progress'
      },
      requests: {
        pending: 2,
        approved: 8,
        rejected: 1,
        total: 11
      },
      notifications: {
        unread: 4,
        urgent: 1,
        last_check: new Date(Date.now() - 900000).toISOString() // 15 mins ago
      },
      biometric: {
        enabled: true,
        available_methods: ['fingerprint', 'face_id'],
        last_setup: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(), // 1 week ago
        setup_required: false
      },
      offline_sync: {
        pending_changes: 3,
        last_sync: new Date(Date.now() - 300000).toISOString(), // 5 mins ago
        connection_status: isOnline ? 'online' : 'offline'
      }
    };
  };

  const generateMobileDemoNotifications = (): MobileNotification[] => {
    return [
      {
        id: '1',
        type: 'approval',
        title: 'Заявка одобрена',
        message: 'Ваш отпуск с 15.08 по 25.08 одобрен менеджером',
        timestamp: new Date(Date.now() - 1800000).toISOString(), // 30 mins ago
        read: false,
        action_required: false
      },
      {
        id: '2', 
        type: 'schedule',
        title: 'Изменение смены',
        message: 'Смена завтра перенесена на 10:00-19:00',
        timestamp: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
        read: false,
        action_required: true
      },
      {
        id: '3',
        type: 'urgent',
        title: 'Срочно: Обновление расписания',
        message: 'Требуется подтверждение работы в выходной день',
        timestamp: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
        read: false,
        action_required: true
      },
      {
        id: '4',
        type: 'system',
        title: 'Обновление системы',
        message: 'Мобильное приложение обновлено до версии 2.1.0',
        timestamp: new Date(Date.now() - 86400000).toISOString(), // 1 day ago
        read: true,
        action_required: false
      }
    ];
  };

  const handleBiometricSetup = async () => {
    try {
      console.log('🔐 Setting up biometric authentication...');
      // Try SPEC-07 biometric setup endpoint
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/mobile/biometric/setup`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          methods: ['fingerprint', 'face_id'],
          device_info: {
            platform: navigator.platform,
            user_agent: navigator.userAgent
          }
        })
      });

      if (response.ok) {
        console.log('✅ Biometric setup successful');
        await loadMobileDashboard(); // Refresh data
      } else {
        console.log('⚠️ Biometric setup demo mode');
      }
    } catch (error) {
      console.log('⚠️ Biometric setup error, demo mode active');
    }
  };

  const getConnectionIcon = () => {
    if (!dashboardData) return <Wifi className="h-4 w-4 text-gray-400" />;
    
    switch (dashboardData.offline_sync.connection_status) {
      case 'online':
        return <Wifi className="h-4 w-4 text-green-500" />;
      case 'offline':
        return <WifiOff className="h-4 w-4 text-red-500" />;
      case 'syncing':
        return <RefreshCw className="h-4 w-4 text-blue-500 animate-spin" />;
      default:
        return <Wifi className="h-4 w-4 text-gray-400" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'in_progress': return 'bg-green-100 text-green-800';
      case 'break': return 'bg-yellow-100 text-yellow-800';
      case 'completed': return 'bg-blue-100 text-blue-800';
      case 'off': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Загрузка личного кабинета...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50" data-testid="mobile-personal-cabinet">
      {/* Mobile Header */}
      <div className="bg-white shadow-sm border-b sticky top-0 z-50">
        <div className="px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setMenuOpen(!menuOpen)}
                className="p-2 hover:bg-gray-100 rounded-lg md:hidden"
              >
                {menuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
              </button>
              <div>
                <h1 className="text-lg font-semibold text-gray-900">{mobileTranslations.dashboard.title}</h1>
                {dashboardData && (
                  <p className="text-sm text-gray-600">
                    {mobileTranslations.dashboard.greeting(dashboardData.employee.name.split(' ')[0])}
                  </p>
                )}
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              {getConnectionIcon()}
              <button
                onClick={loadMobileDashboard}
                disabled={refreshing}
                className="p-2 hover:bg-gray-100 rounded-lg"
              >
                <RefreshCw className={`h-5 w-5 ${refreshing ? 'animate-spin' : ''}`} />
              </button>
            </div>
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="px-4 py-2 bg-yellow-50 border-b border-yellow-200">
            <p className="text-sm text-yellow-800">{error}</p>
          </div>
        )}
      </div>

      {/* Mobile Navigation */}
      {menuOpen && (
        <div className="absolute top-16 left-0 right-0 bg-white border-b shadow-lg z-40">
          <div className="py-2">
            {(['dashboard', 'calendar', 'requests', 'notifications', 'profile'] as const).map((section) => (
              <button
                key={section}
                onClick={() => {
                  setActiveSection(section);
                  setMenuOpen(false);
                }}
                className={`w-full px-4 py-3 text-left hover:bg-gray-50 flex items-center gap-3 ${
                  activeSection === section ? 'bg-blue-50 text-blue-700 border-r-2 border-blue-700' : 'text-gray-700'
                }`}
              >
                {section === 'dashboard' && <Home className="h-5 w-5" />}
                {section === 'calendar' && <Calendar className="h-5 w-5" />}
                {section === 'requests' && <FileText className="h-5 w-5" />}
                {section === 'notifications' && <Bell className="h-5 w-5" />}
                {section === 'profile' && <User className="h-5 w-5" />}
                {mobileTranslations.dashboard.sections[section]}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Dashboard Content */}
      {activeSection === 'dashboard' && dashboardData && (
        <div className="p-4 space-y-4">
          {/* Employee Info Card */}
          <div className="bg-white rounded-lg p-4 shadow-sm">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                <User className="h-6 w-6 text-blue-600" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-gray-900">{dashboardData.employee.name}</h3>
                <p className="text-sm text-gray-600">{dashboardData.employee.position}</p>
                <p className="text-xs text-gray-500">ID: {dashboardData.employee.employee_code}</p>
              </div>
            </div>
          </div>

          {/* Today's Schedule */}
          <div className="bg-white rounded-lg p-4 shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <Clock className="h-5 w-5 text-gray-600" />
              <h3 className="font-medium text-gray-900">{mobileTranslations.schedule.today}</h3>
            </div>
            
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">{mobileTranslations.schedule.shiftStart}:</span>
                <span className="text-sm font-medium">{dashboardData.today_schedule.shift_start || 'Не запланировано'}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">{mobileTranslations.schedule.shiftEnd}:</span>
                <span className="text-sm font-medium">{dashboardData.today_schedule.shift_end || 'Не запланировано'}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Статус:</span>
                <span className={`text-xs px-2 py-1 rounded-full ${getStatusColor(dashboardData.today_schedule.status)}`}>
                  {mobileTranslations.schedule.status[dashboardData.today_schedule.status]}
                </span>
              </div>
            </div>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white rounded-lg p-4 shadow-sm">
              <div className="flex items-center gap-2 mb-2">
                <FileText className="h-5 w-5 text-blue-600" />
                <h3 className="font-medium text-gray-900">{mobileTranslations.requests.pending}</h3>
              </div>
              <p className="text-2xl font-bold text-blue-600">{dashboardData.requests.pending}</p>
              <p className="text-xs text-gray-500">из {dashboardData.requests.total} заявок</p>
            </div>
            
            <div className="bg-white rounded-lg p-4 shadow-sm">
              <div className="flex items-center gap-2 mb-2">
                <Bell className="h-5 w-5 text-red-600" />
                <h3 className="font-medium text-gray-900">Уведомления</h3>
              </div>
              <p className="text-2xl font-bold text-red-600">{dashboardData.notifications.unread}</p>
              <p className="text-xs text-gray-500">{dashboardData.notifications.urgent} срочных</p>
            </div>
          </div>

          {/* Biometric Authentication */}
          <div className="bg-white rounded-lg p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Fingerprint className="h-5 w-5 text-green-600" />
                <div>
                  <h3 className="font-medium text-gray-900">{mobileTranslations.biometric.title}</h3>
                  <p className="text-sm text-gray-600">
                    {dashboardData.biometric.enabled 
                      ? mobileTranslations.biometric.enabled 
                      : mobileTranslations.biometric.disabled
                    }
                  </p>
                </div>
              </div>
              
              {!dashboardData.biometric.enabled && (
                <button
                  onClick={handleBiometricSetup}
                  className="px-3 py-1 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700"
                >
                  {mobileTranslations.biometric.setup}
                </button>
              )}
            </div>
            
            {dashboardData.biometric.enabled && (
              <div className="mt-3 flex gap-2">
                {dashboardData.biometric.available_methods.map((method) => (
                  <span key={method} className="text-xs bg-green-100 text-green-800 px-2 py-1 rounded">
                    {mobileTranslations.biometric.methods[method]}
                  </span>
                ))}
              </div>
            )}
          </div>

          {/* Sync Status */}
          <div className="bg-white rounded-lg p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                {getConnectionIcon()}
                <div>
                  <h3 className="font-medium text-gray-900">
                    {mobileTranslations.sync[dashboardData.offline_sync.connection_status]}
                  </h3>
                  {dashboardData.offline_sync.pending_changes > 0 && (
                    <p className="text-sm text-orange-600">
                      {mobileTranslations.sync.pendingChanges(dashboardData.offline_sync.pending_changes)}
                    </p>
                  )}
                </div>
              </div>
            </div>
            
            <p className="text-xs text-gray-500 mt-2">
              {mobileTranslations.sync.lastSync}: {new Date(dashboardData.offline_sync.last_sync).toLocaleString('ru-RU')}
            </p>
          </div>

          {/* Quick Actions */}
          <div className="space-y-3">
            <button 
              onClick={() => setActiveSection('requests')}
              className="w-full bg-blue-600 text-white rounded-lg p-3 flex items-center justify-center gap-2 hover:bg-blue-700"
            >
              <Plus className="h-5 w-5" />
              {mobileTranslations.requests.createNew}
            </button>
            
            <button 
              onClick={() => setActiveSection('calendar')}
              className="w-full bg-white border border-gray-300 text-gray-700 rounded-lg p-3 flex items-center justify-center gap-2 hover:bg-gray-50"
            >
              <CalendarDays className="h-5 w-5" />
              Открыть календарь
            </button>
          </div>
        </div>
      )}

      {/* Mobile Bottom Navigation (visible on smaller screens) */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 md:hidden">
        <div className="grid grid-cols-5 gap-1">
          {(['dashboard', 'calendar', 'requests', 'notifications', 'profile'] as const).map((section) => (
            <button
              key={section}
              onClick={() => setActiveSection(section)}
              className={`p-3 text-center ${
                activeSection === section 
                  ? 'text-blue-600 bg-blue-50' 
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <div className="flex flex-col items-center gap-1">
                {section === 'dashboard' && <Home className="h-5 w-5" />}
                {section === 'calendar' && <Calendar className="h-5 w-5" />}
                {section === 'requests' && <FileText className="h-5 w-5" />}
                {section === 'notifications' && (
                  <div className="relative">
                    <Bell className="h-5 w-5" />
                    {dashboardData && dashboardData.notifications.unread > 0 && (
                      <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-4 w-4 flex items-center justify-center">
                        {dashboardData.notifications.unread}
                      </span>
                    )}
                  </div>
                )}
                {section === 'profile' && <User className="h-5 w-5" />}
                <span className="text-xs">
                  {section === 'dashboard' && 'Главная'}
                  {section === 'calendar' && 'Календарь'}
                  {section === 'requests' && 'Заявки'}
                  {section === 'notifications' && 'Уведомления'}
                  {section === 'profile' && 'Профиль'}
                </span>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Add bottom padding for mobile navigation */}
      <div className="h-20 md:hidden"></div>
    </div>
  );
};

export default MobilePersonalCabinet;