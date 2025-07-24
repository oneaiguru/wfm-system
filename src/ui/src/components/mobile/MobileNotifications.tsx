import React, { useState, useEffect, useRef, useCallback } from 'react';
import './MobileNotifications.css';

interface Notification {
  id: string;
  type: 'schedule' | 'request' | 'approval' | 'system' | 'shift_change' | 'reminder';
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  action_url?: string;
  action_text?: string;
  metadata?: Record<string, any>;
  sender?: string;
  expires_at?: string;
}

interface NotificationGroup {
  date: string;
  notifications: Notification[];
}

interface NotificationSettings {
  enabled: boolean;
  schedule_changes: boolean;
  request_updates: boolean;
  shift_reminders: boolean;
  system_alerts: boolean;
  sound_enabled: boolean;
  vibration_enabled: boolean;
  quiet_hours_start: string;
  quiet_hours_end: string;
}

interface MobileNotificationsProps {
  employeeId: string;
  onNotificationAction?: (notification: Notification) => void;
}

const MobileNotifications: React.FC<MobileNotificationsProps> = ({
  employeeId,
  onNotificationAction
}) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [groupedNotifications, setGroupedNotifications] = useState<NotificationGroup[]>([]);
  const [settings, setSettings] = useState<NotificationSettings>({
    enabled: true,
    schedule_changes: true,
    request_updates: true,
    shift_reminders: true,
    system_alerts: true,
    sound_enabled: true,
    vibration_enabled: true,
    quiet_hours_start: '22:00',
    quiet_hours_end: '08:00'
  });
  const [filter, setFilter] = useState<'all' | 'unread' | 'urgent'>('all');
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [selectedNotifications, setSelectedNotifications] = useState<Set<string>>(new Set());
  const [selectionMode, setSelectionMode] = useState(false);
  
  const notificationListRef = useRef<HTMLDivElement>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const refreshIntervalRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    loadNotifications();
    loadSettings();
    setupWebSocket();
    setupRefreshInterval();
    requestNotificationPermission();

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
      if (refreshIntervalRef.current) {
        clearInterval(refreshIntervalRef.current);
      }
    };
  }, [employeeId]);

  useEffect(() => {
    groupNotificationsByDate();
  }, [notifications, filter]);

  const loadNotifications = async (refresh = false) => {
    if (refresh) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }

    try {
      // Use I's verified mobile notifications endpoint
      console.log('[MOBILE NOTIFICATIONS] Loading from I\'s verified endpoint...');
      const authToken = localStorage.getItem('authToken');
      
      const response = await fetch('http://localhost:8001/api/v1/mobile/cabinet/notifications', {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const rawData = await response.json();
        console.log('✅ I-VERIFIED mobile notifications loaded:', rawData);
        
        // Parse I's notifications format
        const parsedNotifications: Notification[] = (rawData.notifications || []).map((notif: any) => ({
          id: notif.id || `notif_${Date.now()}`,
          type: notif.type || 'system',
          title: notif.title || 'Уведомление',
          message: notif.message || notif.content || '',
          timestamp: notif.timestamp || notif.created_at || new Date().toISOString(),
          read: notif.read || false,
          priority: notif.priority || 'medium',
          action_url: notif.action_url,
          action_text: notif.action_text || 'Открыть',
          metadata: notif.metadata || {},
          sender: notif.sender || 'Система'
        }));
        
        setNotifications(parsedNotifications);
      } else {
        console.error(`❌ Mobile notifications API error: ${response.status}`);
      }
    } catch (error) {
      console.error('Ошибка загрузки уведомлений:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const loadSettings = async () => {
    try {
      const response = await fetch('/api/v1/mobile/notifications/settings', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setSettings({ ...settings, ...data });
      }
    } catch (error) {
      console.error('Ошибка загрузки настроек:', error);
    }
  };

  const setupWebSocket = () => {
    const token = localStorage.getItem('mobile_auth_token');
    const wsUrl = `ws://localhost:8001/ws/notifications/${employeeId}?token=${token}`;
    
    wsRef.current = new WebSocket(wsUrl);
    
    wsRef.current.onopen = () => {
      console.log('WebSocket соединение установлено');
    };
    
    wsRef.current.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === 'notification') {
        handleNewNotification(data.notification);
      }
    };
    
    wsRef.current.onclose = () => {
      console.log('WebSocket соединение закрыто');
      // Попытка переподключения через 5 секунд
      setTimeout(setupWebSocket, 5000);
    };
    
    wsRef.current.onerror = (error) => {
      console.error('Ошибка WebSocket:', error);
    };
  };

  const setupRefreshInterval = () => {
    // Обновление каждые 2 минуты
    refreshIntervalRef.current = setInterval(() => {
      loadNotifications(true);
    }, 2 * 60 * 1000);
  };

  const requestNotificationPermission = async () => {
    if ('Notification' in window && settings.enabled) {
      if (Notification.permission === 'default') {
        await Notification.requestPermission();
      }
    }
  };

  const handleNewNotification = (notification: Notification) => {
    setNotifications(prev => [notification, ...prev]);
    
    // Показать браузерное уведомление
    if (settings.enabled && Notification.permission === 'granted') {
      showBrowserNotification(notification);
    }
    
    // Воспроизвести звук
    if (settings.sound_enabled && !isQuietHours()) {
      playNotificationSound(notification.priority);
    }
    
    // Вибрация
    if (settings.vibration_enabled && 'vibrate' in navigator) {
      const pattern = getVibrationPattern(notification.priority);
      navigator.vibrate(pattern);
    }
  };

  const showBrowserNotification = (notification: Notification) => {
    const browserNotification = new Notification(notification.title, {
      body: notification.message,
      icon: getNotificationIcon(notification.type),
      tag: notification.id,
      requireInteraction: notification.priority === 'urgent'
    });
    
    browserNotification.onclick = () => {
      window.focus();
      handleNotificationClick(notification);
      browserNotification.close();
    };
    
    // Автоматически закрыть через 5 секунд для обычных уведомлений
    if (notification.priority !== 'urgent') {
      setTimeout(() => browserNotification.close(), 5000);
    }
  };

  const playNotificationSound = (priority: string) => {
    const audio = new Audio();
    switch (priority) {
      case 'urgent':
        audio.src = '/sounds/urgent-notification.mp3';
        break;
      case 'high':
        audio.src = '/sounds/high-notification.mp3';
        break;
      default:
        audio.src = '/sounds/default-notification.mp3';
    }
    audio.play().catch(() => {
      // Ignore audio play errors
    });
  };

  const getVibrationPattern = (priority: string): number[] => {
    switch (priority) {
      case 'urgent':
        return [200, 100, 200, 100, 200];
      case 'high':
        return [100, 50, 100];
      default:
        return [100];
    }
  };

  const isQuietHours = (): boolean => {
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    
    const [startHour, startMin] = settings.quiet_hours_start.split(':').map(Number);
    const [endHour, endMin] = settings.quiet_hours_end.split(':').map(Number);
    
    const quietStart = startHour * 60 + startMin;
    const quietEnd = endHour * 60 + endMin;
    
    if (quietStart < quietEnd) {
      return currentTime >= quietStart && currentTime < quietEnd;
    } else {
      return currentTime >= quietStart || currentTime < quietEnd;
    }
  };

  const getNotificationIcon = (type: string): string => {
    switch (type) {
      case 'schedule': return '/icons/calendar.png';
      case 'request': return '/icons/request.png';
      case 'approval': return '/icons/approval.png';
      case 'shift_change': return '/icons/shift.png';
      case 'reminder': return '/icons/reminder.png';
      default: return '/icons/notification.png';
    }
  };

  const groupNotificationsByDate = () => {
    const filtered = notifications.filter(notification => {
      if (filter === 'unread') return !notification.read;
      if (filter === 'urgent') return notification.priority === 'urgent';
      return true;
    });

    const groups: Record<string, Notification[]> = {};
    
    filtered.forEach(notification => {
      const date = new Date(notification.timestamp).toLocaleDateString('ru-RU');
      if (!groups[date]) {
        groups[date] = [];
      }
      groups[date].push(notification);
    });

    const sortedGroups = Object.entries(groups)
      .map(([date, notifications]) => ({
        date,
        notifications: notifications.sort((a, b) => 
          new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
        )
      }))
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

    setGroupedNotifications(sortedGroups);
  };

  const handleNotificationClick = useCallback(async (notification: Notification) => {
    // Отметить как прочитанное
    if (!notification.read) {
      await markAsRead([notification.id]);
    }
    
    // Выполнить действие
    if (onNotificationAction) {
      onNotificationAction(notification);
    }
    
    // Перейти по ссылке действия
    if (notification.action_url) {
      window.location.href = notification.action_url;
    }
  }, [onNotificationAction]);

  const markAsRead = async (notificationIds: string[]) => {
    try {
      await fetch('/api/v1/mobile/notifications/mark-read', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ notification_ids: notificationIds })
      });
      
      setNotifications(prev => 
        prev.map(n => 
          notificationIds.includes(n.id) 
            ? { ...n, read: true }
            : n
        )
      );
    } catch (error) {
      console.error('Ошибка отметки как прочитанное:', error);
    }
  };

  const markAllAsRead = async () => {
    const unreadIds = notifications
      .filter(n => !n.read)
      .map(n => n.id);
    
    if (unreadIds.length > 0) {
      await markAsRead(unreadIds);
    }
  };

  const deleteSelected = async () => {
    if (selectedNotifications.size === 0) return;
    
    try {
      await fetch('/api/v1/mobile/notifications/delete', {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ 
          notification_ids: Array.from(selectedNotifications) 
        })
      });
      
      setNotifications(prev => 
        prev.filter(n => !selectedNotifications.has(n.id))
      );
      setSelectedNotifications(new Set());
      setSelectionMode(false);
    } catch (error) {
      console.error('Ошибка удаления уведомлений:', error);
    }
  };

  const toggleSelection = (notificationId: string) => {
    setSelectedNotifications(prev => {
      const newSet = new Set(prev);
      if (newSet.has(notificationId)) {
        newSet.delete(notificationId);
      } else {
        newSet.add(notificationId);
      }
      return newSet;
    });
  };

  const getNotificationTypeIcon = (type: string) => {
    switch (type) {
      case 'schedule': return '📅';
      case 'request': return '📝';
      case 'approval': return '✅';
      case 'shift_change': return '🔄';
      case 'reminder': return '⏰';
      case 'system': return '⚙️';
      default: return '📢';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent': return '#e53e3e';
      case 'high': return '#ed8936';
      case 'medium': return '#4299e1';
      default: return '#48bb78';
    }
  };

  const formatRelativeTime = (timestamp: string) => {
    const now = new Date();
    const time = new Date(timestamp);
    const diffMs = now.getTime() - time.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 1) return 'Только что';
    if (diffMins < 60) return `${diffMins} мин назад`;
    if (diffHours < 24) return `${diffHours} ч назад`;
    if (diffDays < 7) return `${diffDays} д назад`;
    
    return time.toLocaleDateString('ru-RU', {
      day: '2-digit',
      month: '2-digit',
      year: '2-digit'
    });
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  if (loading) {
    return (
      <div className="mobile-notifications__loading">
        <div className="mobile-notifications__spinner"></div>
        <p>Загрузка уведомлений...</p>
      </div>
    );
  }

  return (
    <div className="mobile-notifications">
      <div className="mobile-notifications__header">
        <div className="mobile-notifications__title">
          <h2>Уведомления</h2>
          {unreadCount > 0 && (
            <span className="mobile-notifications__badge">{unreadCount}</span>
          )}
        </div>
        
        <div className="mobile-notifications__actions">
          <button
            className="mobile-notifications__action-button"
            onClick={() => setShowSettings(!showSettings)}
          >
            ⚙️
          </button>
          
          <button
            className="mobile-notifications__action-button"
            onClick={() => setSelectionMode(!selectionMode)}
          >
            {selectionMode ? '✖️' : '📋'}
          </button>
          
          <button
            className="mobile-notifications__action-button"
            onClick={() => loadNotifications(true)}
            disabled={refreshing}
          >
            {refreshing ? '🔄' : '↻'}
          </button>
        </div>
      </div>

      {showSettings && (
        <div className="mobile-notifications__settings">
          <h3>Настройки уведомлений</h3>
          
          <label className="mobile-notifications__setting">
            <input
              type="checkbox"
              checked={settings.enabled}
              onChange={(e) => setSettings(prev => ({ ...prev, enabled: e.target.checked }))}
            />
            <span>Включить уведомления</span>
          </label>
          
          <label className="mobile-notifications__setting">
            <input
              type="checkbox"
              checked={settings.sound_enabled}
              onChange={(e) => setSettings(prev => ({ ...prev, sound_enabled: e.target.checked }))}
            />
            <span>Звуковые уведомления</span>
          </label>
          
          <label className="mobile-notifications__setting">
            <input
              type="checkbox"
              checked={settings.vibration_enabled}
              onChange={(e) => setSettings(prev => ({ ...prev, vibration_enabled: e.target.checked }))}
            />
            <span>Вибрация</span>
          </label>
          
          <div className="mobile-notifications__quiet-hours">
            <h4>Тихие часы</h4>
            <div className="mobile-notifications__time-range">
              <input
                type="time"
                value={settings.quiet_hours_start}
                onChange={(e) => setSettings(prev => ({ ...prev, quiet_hours_start: e.target.value }))}
              />
              <span>—</span>
              <input
                type="time"
                value={settings.quiet_hours_end}
                onChange={(e) => setSettings(prev => ({ ...prev, quiet_hours_end: e.target.value }))}
              />
            </div>
          </div>
        </div>
      )}

      <div className="mobile-notifications__filters">
        <button
          className={`mobile-notifications__filter ${filter === 'all' ? 'active' : ''}`}
          onClick={() => setFilter('all')}
        >
          Все
        </button>
        <button
          className={`mobile-notifications__filter ${filter === 'unread' ? 'active' : ''}`}
          onClick={() => setFilter('unread')}
        >
          Непрочитанные
        </button>
        <button
          className={`mobile-notifications__filter ${filter === 'urgent' ? 'active' : ''}`}
          onClick={() => setFilter('urgent')}
        >
          Срочные
        </button>
      </div>

      {selectionMode && (
        <div className="mobile-notifications__selection-bar">
          <span>{selectedNotifications.size} выбрано</span>
          <div>
            <button
              onClick={() => markAsRead(Array.from(selectedNotifications))}
              disabled={selectedNotifications.size === 0}
            >
              Прочитать
            </button>
            <button
              onClick={deleteSelected}
              disabled={selectedNotifications.size === 0}
            >
              Удалить
            </button>
          </div>
        </div>
      )}

      <div className="mobile-notifications__list" ref={notificationListRef}>
        {groupedNotifications.length === 0 ? (
          <div className="mobile-notifications__empty">
            <div className="mobile-notifications__empty-icon">📭</div>
            <h3>Нет уведомлений</h3>
            <p>У вас пока нет новых уведомлений</p>
          </div>
        ) : (
          groupedNotifications.map(group => (
            <div key={group.date} className="mobile-notifications__group">
              <div className="mobile-notifications__group-header">
                {group.date}
              </div>
              
              {group.notifications.map(notification => (
                <div
                  key={notification.id}
                  className={`mobile-notifications__item ${
                    !notification.read ? 'mobile-notifications__item--unread' : ''
                  } ${
                    selectedNotifications.has(notification.id) ? 'mobile-notifications__item--selected' : ''
                  }`}
                  onClick={() => {
                    if (selectionMode) {
                      toggleSelection(notification.id);
                    } else {
                      handleNotificationClick(notification);
                    }
                  }}
                >
                  <div className="mobile-notifications__item-header">
                    <div className="mobile-notifications__item-icon">
                      {getNotificationTypeIcon(notification.type)}
                    </div>
                    
                    <div className="mobile-notifications__item-content">
                      <div className="mobile-notifications__item-title">
                        {notification.title}
                      </div>
                      <div className="mobile-notifications__item-message">
                        {notification.message}
                      </div>
                    </div>
                    
                    <div className="mobile-notifications__item-meta">
                      <div
                        className="mobile-notifications__item-priority"
                        style={{ backgroundColor: getPriorityColor(notification.priority) }}
                      />
                      <div className="mobile-notifications__item-time">
                        {formatRelativeTime(notification.timestamp)}
                      </div>
                    </div>
                  </div>
                  
                  {notification.action_text && (
                    <div className="mobile-notifications__item-action">
                      <button className="mobile-notifications__action-btn">
                        {notification.action_text}
                      </button>
                    </div>
                  )}
                  
                  {selectionMode && (
                    <div className="mobile-notifications__item-checkbox">
                      <input
                        type="checkbox"
                        checked={selectedNotifications.has(notification.id)}
                        onChange={() => toggleSelection(notification.id)}
                      />
                    </div>
                  )}
                </div>
              ))}
            </div>
          ))
        )}
      </div>

      {unreadCount > 0 && !selectionMode && (
        <button
          className="mobile-notifications__mark-all-read"
          onClick={markAllAsRead}
        >
          Отметить все как прочитанные
        </button>
      )}
    </div>
  );
};

export default MobileNotifications;