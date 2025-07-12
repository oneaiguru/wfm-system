import { useState, useEffect, useCallback } from 'react';
import { OfflineData } from '../types/mobile';

// BDD: Offline capability - Downloaded schedules, draft requests, cached notifications
export const useOfflineSync = () => {
  const [isOffline, setIsOffline] = useState(!navigator.onLine);
  const [syncStatus, setSyncStatus] = useState<string | null>(null);
  const [offlineData, setOfflineData] = useState<OfflineData | null>(null);
  const [pendingActions, setPendingActions] = useState<any[]>([]);

  // Monitor online/offline status
  useEffect(() => {
    const handleOnline = () => {
      setIsOffline(false);
      setSyncStatus('Подключение восстановлено. Синхронизация...');
      syncPendingActions();
    };

    const handleOffline = () => {
      setIsOffline(true);
      setSyncStatus('Работа в офлайн режиме');
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Load offline data on mount
  useEffect(() => {
    loadOfflineData();
  }, []);

  const loadOfflineData = () => {
    const stored = localStorage.getItem('offlineData');
    if (stored) {
      setOfflineData(JSON.parse(stored));
    }

    const pending = localStorage.getItem('pendingActions');
    if (pending) {
      setPendingActions(JSON.parse(pending));
    }
  };

  const saveOfflineData = (data: Partial<OfflineData>) => {
    const current = offlineData || {
      schedules: [],
      requests: [],
      notifications: [],
      lastSync: new Date().toISOString(),
      pendingActions: []
    };

    const updated = {
      ...current,
      ...data,
      lastSync: new Date().toISOString()
    };

    setOfflineData(updated);
    localStorage.setItem('offlineData', JSON.stringify(updated));
  };

  const addPendingAction = (action: any) => {
    const updated = [...pendingActions, action];
    setPendingActions(updated);
    localStorage.setItem('pendingActions', JSON.stringify(updated));
  };

  const syncPendingActions = useCallback(async () => {
    if (isOffline || pendingActions.length === 0) return;

    setSyncStatus('Синхронизация данных...');

    try {
      for (const action of pendingActions) {
        await processAction(action);
      }

      // Clear pending actions on successful sync
      setPendingActions([]);
      localStorage.removeItem('pendingActions');
      
      setSyncStatus('Синхронизация завершена');
      setTimeout(() => setSyncStatus(null), 3000);
    } catch (error) {
      setSyncStatus('Ошибка синхронизации');
      setTimeout(() => setSyncStatus(null), 5000);
    }
  }, [isOffline, pendingActions]);

  const processAction = async (action: any) => {
    switch (action.type) {
      case 'CREATE_REQUEST':
        await fetch('/api/mobile/requests', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(action.data)
        });
        break;
      case 'UPDATE_PROFILE':
        await fetch('/api/mobile/profile', {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(action.data)
        });
        break;
      case 'MARK_NOTIFICATION_READ':
        await fetch(`/api/mobile/notifications/${action.data.id}/read`, {
          method: 'POST'
        });
        break;
    }
  };

  const downloadSchedules = async (startDate: Date, endDate: Date) => {
    if (isOffline) {
      setSyncStatus('Нет подключения для загрузки расписания');
      return false;
    }

    setSyncStatus('Загрузка расписания...');

    try {
      const response = await fetch(`/api/mobile/schedules?start=${startDate.toISOString()}&end=${endDate.toISOString()}`);
      const schedules = await response.json();

      saveOfflineData({ schedules });
      setSyncStatus('Расписание загружено');
      setTimeout(() => setSyncStatus(null), 3000);
      
      return true;
    } catch (error) {
      setSyncStatus('Ошибка загрузки расписания');
      setTimeout(() => setSyncStatus(null), 5000);
      return false;
    }
  };

  const saveDraftRequest = (request: any) => {
    const current = offlineData?.requests || [];
    const updated = [...current, { ...request, status: 'draft', id: `draft_${Date.now()}` }];
    
    saveOfflineData({ requests: updated });
    setSyncStatus('Черновик сохранен');
    setTimeout(() => setSyncStatus(null), 2000);
  };

  const submitOfflineRequest = (request: any) => {
    if (isOffline) {
      addPendingAction({
        type: 'CREATE_REQUEST',
        data: request,
        timestamp: new Date().toISOString()
      });
      setSyncStatus('Заявка будет отправлена при подключении');
    } else {
      // Submit immediately if online
      processAction({ type: 'CREATE_REQUEST', data: request });
    }
  };

  const cacheNotifications = async () => {
    if (isOffline) return;

    try {
      const response = await fetch('/api/mobile/notifications');
      const notifications = await response.json();
      
      saveOfflineData({ notifications });
    } catch (error) {
      console.warn('Failed to cache notifications');
    }
  };

  const getOfflineSchedules = () => {
    return offlineData?.schedules || [];
  };

  const getOfflineRequests = () => {
    return offlineData?.requests || [];
  };

  const getOfflineNotifications = () => {
    return offlineData?.notifications || [];
  };

  const clearOfflineData = () => {
    setOfflineData(null);
    setPendingActions([]);
    localStorage.removeItem('offlineData');
    localStorage.removeItem('pendingActions');
    setSyncStatus('Офлайн данные очищены');
    setTimeout(() => setSyncStatus(null), 2000);
  };

  return {
    isOffline,
    syncStatus,
    offlineData,
    pendingActions: pendingActions.length,
    downloadSchedules,
    saveDraftRequest,
    submitOfflineRequest,
    cacheNotifications,
    getOfflineSchedules,
    getOfflineRequests,
    getOfflineNotifications,
    clearOfflineData,
    syncPendingActions
  };
};