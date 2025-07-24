import React, { useState, useEffect } from 'react';
import { Bell, X, Check, Filter, Clock, AlertCircle, Calendar, User, CheckCircle, Loader2 } from 'lucide-react';

interface Notification {
  id: string;
  type: 'request' | 'schedule' | 'system' | 'approval';
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
  priority: 'low' | 'medium' | 'high';
  action_url?: string;
  employee_id?: number;
  request_id?: string;
}

interface NotificationResponse {
  notifications: Notification[];
  total_count: number;
  unread_count: number;
  last_updated: string;
}

// Russian translations
const translations = {
  title: 'Уведомления',
  markAllRead: 'Отметить все как прочитанные',
  viewAll: 'Посмотреть все уведомления',
  noNotifications: 'Уведомлений не найдено',
  filters: {
    all: 'Все',
    request: 'Заявки',
    schedule: 'Расписание',
    system: 'Система',
    approval: 'Одобрения'
  },
  types: {
    request: 'Заявка',
    schedule: 'Расписание',
    system: 'Система',
    approval: 'Одобрение'
  }
};

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

export const NotificationCenter: React.FC = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [filter, setFilter] = useState<'all' | 'request' | 'schedule' | 'system' | 'approval'>('all');
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');
  const [lastUpdated, setLastUpdated] = useState<string>('');

  // Demo data fallback
  const demoNotifications: Notification[] = [
    {
      id: '1',
      type: 'request',
      title: 'Vacation Request Approved',
      message: 'Your vacation request for July 25-29 has been approved by your manager.',
      timestamp: '2025-07-18T10:30:00Z',
      read: false,
      priority: 'high'
    },
    {
      id: '2',
      type: 'schedule',
      title: 'Schedule Updated',
      message: 'Your schedule for next week has been updated. Please review your new shifts.',
      timestamp: '2025-07-18T09:15:00Z',
      read: false,
      priority: 'medium'
    },
    {
      id: '3',
      type: 'system',
      title: 'System Maintenance',
      message: 'Scheduled maintenance will occur tonight from 2:00 AM to 4:00 AM.',
      timestamp: '2025-07-18T08:00:00Z',
      read: true,
      priority: 'low'
    },
    {
      id: '4',
      type: 'approval',
      title: 'Approval Required',
      message: 'John Doe has requested time off for August 1-5. Please review and approve.',
      timestamp: '2025-07-18T07:45:00Z',
      read: false,
      priority: 'high'
    },
    {
      id: '5',
      type: 'request',
      title: 'Request Submitted',
      message: 'Your sick leave request for today has been submitted and is pending approval.',
      timestamp: '2025-07-17T16:30:00Z',
      read: true,
      priority: 'medium'
    },
    {
      id: '6',
      type: 'schedule',
      title: 'Shift Reminder',
      message: 'You have an early shift tomorrow at 7:00 AM. Don\'t forget to set your alarm!',
      timestamp: '2025-07-17T15:00:00Z',
      read: false,
      priority: 'medium'
    }
  ];

  // Load notifications from API
  useEffect(() => {
    loadNotifications();
  }, []);

  const loadNotifications = async () => {
    setLoading(true);
    setError('');
    
    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/notifications`, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data: NotificationResponse = await response.json();
        setNotifications(data.notifications || []);
        setLastUpdated(data.last_updated || new Date().toISOString());
        console.log('✅ Notifications loaded:', data.notifications.length);
      } else {
        // Use demo data as fallback
        console.log('⚠️ Notifications API not available, using demo data');
        setNotifications(demoNotifications);
        setError('Using demo notifications - API not available');
      }
    } catch (err) {
      console.log('⚠️ Notifications API error, using demo data');
      setNotifications(demoNotifications);
      setError('Network error - using demo notifications');
    } finally {
      setLoading(false);
    }
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  const filteredNotifications = notifications.filter(n => 
    filter === 'all' || n.type === filter
  );

  const markAsRead = async (id: string) => {
    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/notifications/${id}/read`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        setNotifications(prev => prev.map(n => 
          n.id === id ? { ...n, read: true } : n
        ));
        console.log('✅ Notification marked as read:', id);
      } else {
        // Still update UI optimistically
        setNotifications(prev => prev.map(n => 
          n.id === id ? { ...n, read: true } : n
        ));
        console.log('⚠️ Mark as read API failed, updated locally');
      }
    } catch (err) {
      // Still update UI optimistically
      setNotifications(prev => prev.map(n => 
        n.id === id ? { ...n, read: true } : n
      ));
      console.log('⚠️ Mark as read network error, updated locally');
    }
  };

  const markAllAsRead = async () => {
    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/notifications/read-all`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        setNotifications(prev => prev.map(n => ({ ...n, read: true })));
        console.log('✅ All notifications marked as read');
      } else {
        // Still update UI optimistically
        setNotifications(prev => prev.map(n => ({ ...n, read: true })));
        console.log('⚠️ Mark all as read API failed, updated locally');
      }
    } catch (err) {
      // Still update UI optimistically
      setNotifications(prev => prev.map(n => ({ ...n, read: true })));
      console.log('⚠️ Mark all as read network error, updated locally');
    }
  };

  const deleteNotification = async (id: string) => {
    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/notifications/${id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        setNotifications(prev => prev.filter(n => n.id !== id));
        console.log('✅ Notification deleted:', id);
      } else {
        // Still update UI optimistically
        setNotifications(prev => prev.filter(n => n.id !== id));
        console.log('⚠️ Delete notification API failed, updated locally');
      }
    } catch (err) {
      // Still update UI optimistically
      setNotifications(prev => prev.filter(n => n.id !== id));
      console.log('⚠️ Delete notification network error, updated locally');
    }
  };

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'request': return User;
      case 'schedule': return Calendar;
      case 'system': return AlertCircle;
      case 'approval': return CheckCircle;
      default: return Bell;
    }
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'request': return 'bg-blue-100 text-blue-800';
      case 'schedule': return 'bg-green-100 text-green-800';
      case 'system': return 'bg-yellow-100 text-yellow-800';
      case 'approval': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'border-red-500';
      case 'medium': return 'border-yellow-500';
      case 'low': return 'border-green-500';
      default: return 'border-gray-300';
    }
  };

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return date.toLocaleDateString();
  };

  return (
    <div className="relative">
      {/* Notification Bell */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
        title={translations.title}
      >
        {loading ? <Loader2 className="h-6 w-6 animate-spin" /> : <Bell className="h-6 w-6" />}
        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center font-medium">
            {unreadCount > 9 ? '9+' : unreadCount}
          </span>
        )}
      </button>

      {/* Notification Dropdown */}
      {isOpen && (
        <div className="absolute right-0 mt-2 w-96 bg-white rounded-lg shadow-xl border border-gray-200 z-50">
          {/* Header */}
          <div className="p-4 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">{translations.title}</h3>
              <div className="flex items-center gap-2">
                {unreadCount > 0 && (
                  <button
                    onClick={markAllAsRead}
                    className="text-sm text-blue-600 hover:text-blue-800 font-medium"
                  >
                    {translations.markAllRead}
                  </button>
                )}
                <button
                  onClick={() => setIsOpen(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
            </div>
            
            {error && (
              <div className="mt-2 text-xs text-yellow-600 bg-yellow-50 px-2 py-1 rounded">
                {error}
              </div>
            )}

            {/* Filter Tabs */}
            <div className="flex gap-1 mt-3 bg-gray-100 rounded-lg p-1">
              {[
                { key: 'all', label: translations.filters.all },
                { key: 'request', label: translations.filters.request },
                { key: 'schedule', label: translations.filters.schedule },
                { key: 'system', label: translations.filters.system },
                { key: 'approval', label: translations.filters.approval }
              ].map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setFilter(tab.key as any)}
                  className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
                    filter === tab.key
                      ? 'bg-white text-blue-600 shadow-sm'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          {/* Notifications List */}
          <div className="max-h-96 overflow-y-auto">
            {filteredNotifications.length === 0 ? (
              <div className="p-8 text-center">
                <Bell className="h-12 w-12 text-gray-400 mx-auto mb-3" />
                <p className="text-gray-500">{translations.noNotifications}</p>
              </div>
            ) : (
              <div className="divide-y divide-gray-100">
                {filteredNotifications.map((notification) => {
                  const Icon = getNotificationIcon(notification.type);
                  return (
                    <div
                      key={notification.id}
                      className={`p-4 hover:bg-gray-50 transition-colors ${
                        !notification.read ? 'bg-blue-50' : ''
                      }`}
                    >
                      <div className="flex items-start gap-3">
                        <div className={`p-2 rounded-lg ${getTypeColor(notification.type)}`}>
                          <Icon className="h-4 w-4" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <h4 className={`text-sm font-medium ${
                              !notification.read ? 'text-gray-900' : 'text-gray-700'
                            }`}>
                              {notification.title}
                            </h4>
                            {!notification.read && (
                              <div className="w-2 h-2 bg-blue-500 rounded-full" />
                            )}
                          </div>
                          <p className="text-sm text-gray-600 mb-2">
                            {notification.message}
                          </p>
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                              <Clock className="h-3 w-3 text-gray-400" />
                              <span className="text-xs text-gray-500">
                                {formatTimestamp(notification.timestamp)}
                              </span>
                            </div>
                            <div className="flex items-center gap-1">
                              {!notification.read && (
                                <button
                                  onClick={() => markAsRead(notification.id)}
                                  className="text-blue-600 hover:text-blue-800 p-1"
                                  title="Mark as read"
                                >
                                  <Check className="h-4 w-4" />
                                </button>
                              )}
                              <button
                                onClick={() => deleteNotification(notification.id)}
                                className="text-red-600 hover:text-red-800 p-1"
                                title="Delete notification"
                              >
                                <X className="h-4 w-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="p-3 border-t border-gray-200 bg-gray-50">
            <button 
              onClick={() => window.location.href = '/notifications'}
              className="w-full text-center text-sm text-blue-600 hover:text-blue-800 font-medium"
            >
              {translations.viewAll}
            </button>
            {lastUpdated && (
              <div className="text-xs text-gray-500 text-center mt-1">
                Обновлено: {new Date(lastUpdated).toLocaleString('ru-RU')}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default NotificationCenter;