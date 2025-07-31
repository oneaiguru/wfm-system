import React, { useState, useEffect, useRef } from 'react';
import './MobileOfflineIndicator.css';

interface SyncStatus {
  status: 'online' | 'offline' | 'syncing' | 'error';
  last_sync: string;
  pending_uploads: number;
  pending_downloads: number;
  connection_quality: 'excellent' | 'good' | 'poor' | 'none';
}

interface OfflineData {
  schedules: number;
  requests: number;
  notifications: number;
  profiles: number;
  total_size: number;
}

interface MobileOfflineIndicatorProps {
  onSyncRequest?: () => void;
  onOfflineModeToggle?: (enabled: boolean) => void;
  position?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left';
  showDetails?: boolean;
}

const MobileOfflineIndicator: React.FC<MobileOfflineIndicatorProps> = ({
  onSyncRequest,
  onOfflineModeToggle,
  position = 'top-right',
  showDetails = false
}) => {
  const [syncStatus, setSyncStatus] = useState<SyncStatus>({
    status: 'online',
    last_sync: new Date().toISOString(),
    pending_uploads: 0,
    pending_downloads: 0,
    connection_quality: 'excellent'
  });
  const [offlineData, setOfflineData] = useState<OfflineData>({
    schedules: 0,
    requests: 0,
    notifications: 0,
    profiles: 0,
    total_size: 0
  });
  const [isExpanded, setIsExpanded] = useState(false);
  const [offlineModeEnabled, setOfflineModeEnabled] = useState(false);
  const [autoSyncEnabled, setAutoSyncEnabled] = useState(true);
  const [syncInProgress, setSyncInProgress] = useState(false);
  const [syncComplete, setSyncComplete] = useState(false);
  
  const indicatorRef = useRef<HTMLDivElement>(null);
  const syncIntervalRef = useRef<NodeJS.Timeout>();
  const connectionCheckRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    initializeOfflineMode();
    startConnectionMonitoring();
    
    // Cleanup on unmount
    return () => {
      if (syncIntervalRef.current) {
        clearInterval(syncIntervalRef.current);
      }
      if (connectionCheckRef.current) {
        clearInterval(connectionCheckRef.current);
      }
    };
  }, []);

  useEffect(() => {
    if (autoSyncEnabled && syncStatus.status === 'online') {
      // Auto sync every 5 minutes when online
      syncIntervalRef.current = setInterval(() => {
        performSync();
      }, 5 * 60 * 1000);
    } else if (syncIntervalRef.current) {
      clearInterval(syncIntervalRef.current);
    }

    return () => {
      if (syncIntervalRef.current) {
        clearInterval(syncIntervalRef.current);
      }
    };
  }, [autoSyncEnabled, syncStatus.status]);

  const initializeOfflineMode = () => {
    // Check if offline mode is supported
    if ('serviceWorker' in navigator && 'caches' in window) {
      loadOfflineData();
      loadSyncStatus();
      
      // Register service worker for offline support
      navigator.serviceWorker.register('/sw.js')
        .then(registration => {
          console.log('Service Worker зарегистрирован:', registration);
        })
        .catch(error => {
          console.error('Ошибка регистрации Service Worker:', error);
        });
    }
  };

  const startConnectionMonitoring = () => {
    // Monitor connection status
    const updateConnectionStatus = () => {
      const connection = (navigator as any).connection;
      let quality: 'excellent' | 'good' | 'poor' | 'none' = 'excellent';
      
      if (!navigator.onLine) {
        quality = 'none';
      } else if (connection) {
        const effectiveType = connection.effectiveType;
        if (effectiveType === '4g') {
          quality = 'excellent';
        } else if (effectiveType === '3g') {
          quality = 'good';
        } else {
          quality = 'poor';
        }
      }
      
      setSyncStatus(prev => ({
        ...prev,
        status: navigator.onLine ? 'online' : 'offline',
        connection_quality: quality
      }));
    };

    // Initial check
    updateConnectionStatus();
    
    // Listen for connection changes
    window.addEventListener('online', updateConnectionStatus);
    window.addEventListener('offline', updateConnectionStatus);
    
    // Check connection quality every 30 seconds
    connectionCheckRef.current = setInterval(updateConnectionStatus, 30000);
    
    return () => {
      window.removeEventListener('online', updateConnectionStatus);
      window.removeEventListener('offline', updateConnectionStatus);
      if (connectionCheckRef.current) {
        clearInterval(connectionCheckRef.current);
      }
    };
  };

  const loadOfflineData = async () => {
    try {
      const response = await fetch('/api/v1/mobile/sync/offline-data', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setOfflineData(data);
      }
    } catch (error) {
      console.error('Ошибка загрузки оффлайн данных:', error);
    }
  };

  const loadSyncStatus = async () => {
    try {
      const response = await fetch('/api/v1/mobile/sync/status', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const status = await response.json();
        setSyncStatus(prev => ({ ...prev, ...status }));
      }
    } catch (error) {
      console.error('Ошибка загрузки статуса синхронизации:', error);
    }
  };

  const performSync = async () => {
    if (syncInProgress || syncStatus.status !== 'online') return;
    
    setSyncInProgress(true);
    setSyncStatus(prev => ({ ...prev, status: 'syncing' }));
    
    try {
      // Upload pending changes
      if (syncStatus.pending_uploads > 0) {
        await uploadPendingChanges();
      }
      
      // Download latest data
      if (syncStatus.pending_downloads > 0) {
        await downloadLatestData();
      }
      
      // Update sync status
      setSyncStatus(prev => ({
        ...prev,
        status: 'online',
        last_sync: new Date().toISOString(),
        pending_uploads: 0,
        pending_downloads: 0
      }));
      
      // Refresh offline data
      await loadOfflineData();
      
      // Show sync complete notification
      setSyncComplete(true);
      setTimeout(() => setSyncComplete(false), 3000);
      
      if (onSyncRequest) {
        onSyncRequest();
      }
      
    } catch (error) {
      console.error('Ошибка синхронизации:', error);
      setSyncStatus(prev => ({ ...prev, status: 'error' }));
    } finally {
      setSyncInProgress(false);
    }
  };

  const uploadPendingChanges = async () => {
    const pendingChanges = await getPendingChanges();
    
    for (const change of pendingChanges) {
      try {
        await fetch('/api/v1/mobile/sync/upload', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(change)
        });
        
        // Remove from pending changes
        await removePendingChange(change.id);
      } catch (error) {
        console.error('Ошибка загрузки изменения:', error);
      }
    }
  };

  const downloadLatestData = async () => {
    try {
      const response = await fetch('/api/v1/mobile/sync/download', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.ok) {
        const data = await response.json();
        await storeOfflineData(data);
      }
    } catch (error) {
      console.error('Ошибка скачивания данных:', error);
    }
  };

  const getPendingChanges = async (): Promise<any[]> => {
    // Get pending changes from IndexedDB or localStorage
    const changes = localStorage.getItem('pending_changes');
    return changes ? JSON.parse(changes) : [];
  };

  const removePendingChange = async (changeId: string) => {
    const changes = await getPendingChanges();
    const filteredChanges = changes.filter(c => c.id !== changeId);
    localStorage.setItem('pending_changes', JSON.stringify(filteredChanges));
  };

  const storeOfflineData = async (data: any) => {
    // Store data for offline access
    if ('caches' in window) {
      const cache = await caches.open('wfm-mobile-data-v1');
      const response = new Response(JSON.stringify(data));
      await cache.put('/offline-data', response);
    }
  };

  const toggleOfflineMode = () => {
    const newMode = !offlineModeEnabled;
    setOfflineModeEnabled(newMode);
    
    if (onOfflineModeToggle) {
      onOfflineModeToggle(newMode);
    }
    
    localStorage.setItem('offline_mode_enabled', newMode.toString());
  };

  const clearOfflineData = async () => {
    if (confirm('Очистить все оффлайн данные? Это действие нельзя отменить.')) {
      try {
        // Clear caches
        if ('caches' in window) {
          const cacheNames = await caches.keys();
          await Promise.all(
            cacheNames.map(name => caches.delete(name))
          );
        }
        
        // Clear local storage
        localStorage.removeItem('pending_changes');
        localStorage.removeItem('offline_data');
        
        // Reload offline data
        await loadOfflineData();
        
        alert('Оффлайн данные очищены');
      } catch (error) {
        console.error('Ошибка очистки оффлайн данных:', error);
        alert('Ошибка очистки данных');
      }
    }
  };

  const getStatusIcon = () => {
    switch (syncStatus.status) {
      case 'online':
        return '🟢';
      case 'offline':
        return '🔴';
      case 'syncing':
        return '🔄';
      case 'error':
        return '⚠️';
      default:
        return '❓';
    }
  };

  const getConnectionIcon = () => {
    switch (syncStatus.connection_quality) {
      case 'excellent':
        return '📶';
      case 'good':
        return '📶';
      case 'poor':
        return '📶';
      case 'none':
        return '📵';
      default:
        return '📶';
    }
  };

  const formatLastSync = () => {
    const lastSync = new Date(syncStatus.last_sync);
    const now = new Date();
    const diffMs = now.getTime() - lastSync.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    
    if (diffMins < 1) return 'Только что';
    if (diffMins < 60) return `${diffMins} мин назад`;
    if (diffMins < 1440) return `${Math.floor(diffMins / 60)} ч назад`;
    return lastSync.toLocaleDateString('ru-RU');
  };

  const formatDataSize = (bytes: number): string => {
    if (bytes === 0) return '0 Б';
    const k = 1024;
    const sizes = ['Б', 'КБ', 'МБ', 'ГБ'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <div 
      ref={indicatorRef}
      data-testid="offline-indicator"
      className={`offline-indicator offline-indicator--${position} ${
        isExpanded ? 'offline-indicator--expanded' : ''
      }`}
    >
      <div 
        className="offline-indicator__badge"
        onClick={() => setIsExpanded(!isExpanded)}
      >
        <span className="offline-indicator__status-icon">
          {getStatusIcon()}
        </span>
        
        {(syncStatus.pending_uploads > 0 || syncStatus.pending_downloads > 0) && (
          <span className="offline-indicator__pending-badge">
            {syncStatus.pending_uploads + syncStatus.pending_downloads}
          </span>
        )}
        
        <span className="offline-indicator__connection-icon">
          {getConnectionIcon()}
        </span>
      </div>

      {isExpanded && (
        <div className="offline-indicator__details">
          <div className="offline-indicator__header">
            <h3>Статус синхронизации</h3>
            <button
              className="offline-indicator__close"
              onClick={() => setIsExpanded(false)}
            >
              ❌
            </button>
          </div>
          
          <div data-testid="sync-status" className="offline-indicator__status-section">
            <div className="offline-indicator__status-row">
              <span>Статус:</span>
              <span className={`offline-indicator__status-text offline-indicator__status-text--${syncStatus.status}`}>
                {syncStatus.status === 'online' && 'В сети'}
                {syncStatus.status === 'offline' && 'Оффлайн'}
                {syncStatus.status === 'syncing' && 'Синхронизация'}
                {syncStatus.status === 'error' && 'Ошибка'}
              </span>
            </div>
            
            <div className="offline-indicator__status-row">
              <span>Качество связи:</span>
              <span>{syncStatus.connection_quality}</span>
            </div>
            
            <div className="offline-indicator__status-row">
              <span>Последняя синхронизация:</span>
              <span>{formatLastSync()}</span>
            </div>
            
            {(syncStatus.pending_uploads > 0 || syncStatus.pending_downloads > 0) && (
              <div className="offline-indicator__pending">
                <div className="offline-indicator__status-row">
                  <span>К загрузке:</span>
                  <span>{syncStatus.pending_uploads}</span>
                </div>
                <div className="offline-indicator__status-row">
                  <span>К скачиванию:</span>
                  <span>{syncStatus.pending_downloads}</span>
                </div>
              </div>
            )}
          </div>
          
          {showDetails && (
            <div className="offline-indicator__data-section">
              <h4>Оффлайн данные</h4>
              <div className="offline-indicator__data-grid">
                <div className="offline-indicator__data-item">
                  <span>📅 Расписания:</span>
                  <span>{offlineData.schedules}</span>
                </div>
                <div className="offline-indicator__data-item">
                  <span>📝 Заявки:</span>
                  <span>{offlineData.requests}</span>
                </div>
                <div className="offline-indicator__data-item">
                  <span>🔔 Уведомления:</span>
                  <span>{offlineData.notifications}</span>
                </div>
                <div className="offline-indicator__data-item">
                  <span>👤 Профили:</span>
                  <span>{offlineData.profiles}</span>
                </div>
                <div className="offline-indicator__data-item">
                  <span>💾 Размер:</span>
                  <span>{formatDataSize(offlineData.total_size)}</span>
                </div>
              </div>
            </div>
          )}
          
          <div className="offline-indicator__controls">
            <button
              className="offline-indicator__button offline-indicator__button--primary"
              onClick={performSync}
              disabled={syncInProgress || syncStatus.status !== 'online'}
            >
              {syncInProgress ? '🔄 Синхронизация...' : '🔄 Синхронизировать'}
            </button>
            
            <div className="offline-indicator__toggle">
              <label>
                <input
                  type="checkbox"
                  checked={autoSyncEnabled}
                  onChange={(e) => setAutoSyncEnabled(e.target.checked)}
                />
                <span>Автосинхронизация</span>
              </label>
            </div>
            
            <div className="offline-indicator__toggle">
              <label>
                <input
                  type="checkbox"
                  checked={offlineModeEnabled}
                  onChange={toggleOfflineMode}
                />
                <span>Оффлайн режим</span>
              </label>
            </div>
            
            {showDetails && (
              <button
                className="offline-indicator__button offline-indicator__button--danger"
                onClick={clearOfflineData}
              >
                🗑️ Очистить данные
              </button>
            )}
          </div>
          
          {syncComplete && (
            <div data-testid="sync-complete" className="offline-indicator__sync-complete">
              ✅ Request synced successfully
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default MobileOfflineIndicator;