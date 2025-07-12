import React, { useState, useEffect } from 'react';
import { Bell, Calendar, AlertCircle, Info, CheckCircle, X } from 'lucide-react';
import { MobileNotification } from '../../types/mobile';
import { useOfflineSync } from '../../hooks/useOfflineSync';

// BDD: Push notifications with deep linking to relevant sections
const MobileNotifications: React.FC = () => {
  const [notifications, setNotifications] = useState<MobileNotification[]>([]);
  const [filter, setFilter] = useState<'all' | 'unread'>('all');
  const { isOffline, getOfflineNotifications } = useOfflineSync();

  useEffect(() => {
    loadNotifications();
  }, [isOffline]);

  const loadNotifications = async () => {
    if (isOffline) {
      // Load from offline cache
      const cached = getOfflineNotifications();
      setNotifications(cached);
    } else {
      try {
        const response = await fetch('/api/mobile/notifications');
        const data = await response.json();
        setNotifications(data);
      } catch (error) {
        // Fallback to mock data
        setNotifications(mockNotifications);
      }
    }
  };

  // BDD: System alerts with read/unread filtering
  const mockNotifications: MobileNotification[] = [
    {
      id: 'NOT001',
      type: 'schedule',
      title: 'Изменение расписания',
      message: 'Ваша смена на 18 июля перенесена с 09:00 на 10:00',
      timestamp: '2024-07-15T14:30:00Z',
      read: false,
      actionUrl: '/mobile/calendar?date=2024-07-18',
      priority: 'high'
    },
    {
      id: 'NOT002',
      type: 'request',
      title: 'Заявка одобрена',
      message: 'Ваша заявка на отгул 20 июля одобрена руководителем',
      timestamp: '2024-07-15T10:15:00Z',
      read: false,
      actionUrl: '/mobile/requests',
      priority: 'medium'
    },
    {
      id: 'NOT003',
      type: 'announcement',
      title: 'Собрание отдела',
      message: 'Завтра в 15:00 состоится собрание отдела в конференц-зале',
      timestamp: '2024-07-14T16:45:00Z',
      read: true,
      priority: 'medium'
    },
    {
      id: 'NOT004',
      type: 'reminder',
      title: 'Напоминание',
      message: 'Через час начинается ваша смена',
      timestamp: '2024-07-15T08:00:00Z',
      read: true,
      priority: 'low'
    }
  ];

  const getIcon = (type: string) => {
    switch (type) {
      case 'schedule': return <Calendar className="h-5 w-5" />;
      case 'request': return <CheckCircle className="h-5 w-5" />;
      case 'announcement': return <Info className="h-5 w-5" />;
      case 'reminder': return <Bell className="h-5 w-5" />;
      default: return <AlertCircle className="h-5 w-5" />;
    }
  };

  const getIconColor = (type: string, priority: string) => {
    if (priority === 'high') return 'text-red-600';
    
    switch (type) {
      case 'schedule': return 'text-blue-600';
      case 'request': return 'text-green-600';
      case 'announcement': return 'text-purple-600';
      case 'reminder': return 'text-yellow-600';
      default: return 'text-gray-600';
    }
  };

  const markAsRead = async (notificationId: string) => {
    if (isOffline) {
      // Add to pending actions for sync later
      return;
    }

    try {
      await fetch(`/api/mobile/notifications/${notificationId}/read`, {
        method: 'POST'
      });
      
      setNotifications(prev => 
        prev.map(n => n.id === notificationId ? { ...n, read: true } : n)
      );
    } catch (error) {
      // Update locally even if API fails
      setNotifications(prev => 
        prev.map(n => n.id === notificationId ? { ...n, read: true } : n)
      );
    }
  };

  const handleNotificationClick = (notification: MobileNotification) => {
    if (!notification.read) {
      markAsRead(notification.id);
    }
    
    // BDD: Deep linking to relevant sections
    if (notification.actionUrl) {
      window.location.href = notification.actionUrl;
    }
  };

  const markAllAsRead = async () => {
    if (isOffline) return;

    try {
      await fetch('/api/mobile/notifications/mark-all-read', {
        method: 'POST'
      });
      
      setNotifications(prev => prev.map(n => ({ ...n, read: true })));
    } catch (error) {
      setNotifications(prev => prev.map(n => ({ ...n, read: true })));
    }
  };

  const filteredNotifications = notifications.filter(n => 
    filter === 'all' || (filter === 'unread' && !n.read)
  );

  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-gray-900">Уведомления</h2>
          {unreadCount > 0 && (
            <p className="text-sm text-gray-600">Непрочитанных: {unreadCount}</p>
          )}
        </div>
        {unreadCount > 0 && (
          <button
            onClick={markAllAsRead}
            disabled={isOffline}
            className="text-sm text-blue-600 hover:text-blue-700 disabled:opacity-50"
          >
            Прочитать все
          </button>
        )}
      </div>

      {/* Filter Tabs */}
      <div className="bg-white rounded-lg shadow-sm">
        <div className="flex border-b">
          <button
            onClick={() => setFilter('all')}
            className={`flex-1 px-4 py-3 text-center font-medium transition-colors ${
              filter === 'all'
                ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            Все ({notifications.length})
          </button>
          <button
            onClick={() => setFilter('unread')}
            className={`flex-1 px-4 py-3 text-center font-medium transition-colors ${
              filter === 'unread'
                ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            Непрочитанные ({unreadCount})
          </button>
        </div>

        {/* Notifications List */}
        <div className="divide-y divide-gray-200">
          {filteredNotifications.length > 0 ? (
            filteredNotifications.map((notification) => (
              <div
                key={notification.id}
                onClick={() => handleNotificationClick(notification)}
                className={`p-4 hover:bg-gray-50 cursor-pointer transition-colors ${
                  !notification.read ? 'bg-blue-50' : ''
                }`}
              >
                <div className="flex items-start space-x-3">
                  <div className={`mt-1 ${getIconColor(notification.type, notification.priority)}`}>
                    {getIcon(notification.type)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <p className={`text-sm font-medium ${
                          !notification.read ? 'text-gray-900' : 'text-gray-700'
                        }`}>
                          {notification.title}
                        </p>
                        <p className={`text-sm mt-1 ${
                          !notification.read ? 'text-gray-700' : 'text-gray-600'
                        }`}>
                          {notification.message}
                        </p>
                        <p className="text-xs text-gray-500 mt-1">
                          {new Date(notification.timestamp).toLocaleString('ru-RU')}
                        </p>
                      </div>
                      <div className="flex items-center space-x-2 ml-2">
                        {notification.priority === 'high' && (
                          <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                        )}
                        {!notification.read && (
                          <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className="p-8 text-center">
              <Bell className="h-12 w-12 text-gray-400 mx-auto mb-3" />
              <p className="text-gray-600">
                {filter === 'unread' ? 'Нет непрочитанных уведомлений' : 'Уведомлений нет'}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Offline Status */}
      {isOffline && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <AlertCircle className="h-5 w-5 text-yellow-600" />
            <span className="text-sm text-yellow-700">
              Работа в офлайн режиме. Показаны кешированные уведомления.
            </span>
          </div>
        </div>
      )}
    </div>
  );
};

export default MobileNotifications;